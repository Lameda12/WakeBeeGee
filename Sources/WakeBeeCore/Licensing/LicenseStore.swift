import Foundation
import Observation

@MainActor @Observable
public final class LicenseStore {
    public private(set) var isUnlocked = false
    public private(set) var isBusy = false
    public private(set) var errorMessage: String?
    public private(set) var notice: String?
    private var record: LicenseRecord?
    @ObservationIgnored private let storage: any LicenseStorage
    @ObservationIgnored private let client: any LicenseServing
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var lastAttempt: Date?

    public var hasSavedLicense: Bool { record != nil }
    public var maskedKey: String? { record.map { "••••–\($0.key.suffix(4))" } }
    public var lastValidatedAt: Date? { record?.validatedAt }

    public init(storage: any LicenseStorage, client: any LicenseServing = PolarLicenseClient(),
                clock: @escaping () -> Date = { .now }) {
        self.storage = storage; self.client = client; self.clock = clock
        do { record = try storage.load() }
        catch { errorMessage = ((error as? LicenseError) ?? .storage).localizedDescription }
        updateAccess()
    }

    /// Called by the app's existing monitor, including when its windows are closed.
    public func refreshIfNeeded() {
        updateAccess()
        guard let record, !isBusy else { return }
        let now = clock()
        guard lastAttempt.map({ now.timeIntervalSince($0) >= 3600 }) ?? true,
              record.validatedAt.map({ now.timeIntervalSince($0) >= WakeBeeLicense.validationInterval }) ?? true else { return }
        lastAttempt = now
        Task { await recheck() }
    }

    public func activate(_ input: String) async {
        guard !isBusy else { return }
        let key = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.utf8.count <= 512, !key.contains(where: { $0.isWhitespace || $0.isNewline }) else {
            errorMessage = LicenseError.emptyKey.localizedDescription
            return
        }
        // Reuse a saved allocation on retry; never consume a second device slot.
        if let record, record.key != key {
            errorMessage = "Remove the saved license before entering a different key."
            return
        }
        await verify(key: key)
    }

    public func recheck() async {
        guard let record, !isBusy else { return }
        await verify(key: record.key)
    }

    private func verify(key: String) async {
        isBusy = true; errorMessage = nil; notice = nil; lastAttempt = clock()
        defer { isBusy = false; updateAccess() }
        do {
            var candidate = record ?? LicenseRecord(key: key)
            var license = try await client.validate(key: key, activationID: candidate.activationID)
            try license.check(activationID: candidate.activationID, at: clock())
            if let limit = license.limitActivations, limit > 0, candidate.activationID == nil {
                let activation = try await client.activate(key: key)
                candidate.activationID = activation
                // Persist the allocation before the next request. A timeout must
                // not cause the next attempt to create another activation.
                candidate.validatedAt = nil
                do { try storage.save(candidate); record = candidate }
                catch {
                    do { try await client.deactivate(key: key, activationID: activation) }
                    catch { throw LicenseError.cleanup }
                    throw (error as? LicenseError) ?? .storage
                }
                license = try await client.validate(key: key, activationID: activation)
                try license.check(activationID: activation, at: clock())
            }
            candidate.validatedAt = clock()
            candidate.expiresAt = license.expiresAt
            candidate.rejected = false
            do { try storage.save(candidate) } catch { throw (error as? LicenseError) ?? .storage }
            record = candidate
        } catch {
            let failure = (error as? LicenseError) ?? .unavailable
            if failure.isDefinitive, var existing = record {
                existing.rejected = true
                record = existing
                // Retain the rejection in memory even if Keychain is temporarily locked.
                do { try storage.save(existing) }
                catch { errorMessage = ((error as? LicenseError) ?? .storage).localizedDescription }
            }
            if record?.allowsUse(at: clock()) == true, !failure.isDefinitive {
                notice = "Using your saved license. WakeBee will try again automatically."
            }
            errorMessage = errorMessage ?? failure.localizedDescription
        }
    }

    /// Call only after the user ends protection; removing a license must not put
    /// an unattended, closed-lid Mac to sleep in the middle of its current work.
    public func remove() async {
        guard !isBusy, let record else { return }
        isBusy = true; errorMessage = nil; notice = nil
        defer { isBusy = false; updateAccess() }
        do {
            if let activation = record.activationID {
                try await client.deactivate(key: record.key, activationID: activation)
                // Once Polar releases the device, a local deletion failure must
                // not leave that activation usable from the cache.
                var removed = record
                removed.rejected = true
                self.record = removed
                try? storage.save(removed)
            }
            do { try storage.remove() } catch { throw (error as? LicenseError) ?? .storage }
            self.record = nil
            lastAttempt = nil
        } catch { errorMessage = ((error as? LicenseError) ?? .unavailable).localizedDescription }
    }

    private func updateAccess() {
        let access = record?.allowsUse(at: clock()) ?? false
        if isUnlocked != access { isUnlocked = access }
    }
}
