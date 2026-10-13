import Foundation
import Testing
@testable import WakeBeeCore

private let licenseID = UUID(uuidString: "8c32fc18-b923-4a40-879c-af49d2af25e6")!
private let activationID = UUID(uuidString: "189eff66-fcbc-4815-a991-43830d1fa3dd")!
private let licenseTime = Date(timeIntervalSince1970: 1_900_000_000)

private func granted(limit: Int? = nil, activation: UUID? = nil, benefit: UUID = WakeBeeLicense.benefitID) -> PolarLicense {
    PolarLicense(id: licenseID, organizationID: WakeBeeLicense.organizationID, benefitID: benefit,
                 status: "granted", limitActivations: limit, expiresAt: nil,
                 activation: activation.map { .init(id: $0, licenseKeyID: licenseID) })
}

@MainActor private final class MemoryLicenseStorage: LicenseStorage {
    var record: LicenseRecord?
    var saves = 0
    var failSaves = false
    var failRemoval = false
    var removalError: LicenseError?
    init(_ record: LicenseRecord? = nil) { self.record = record }
    func load() throws -> LicenseRecord? { record }
    func save(_ record: LicenseRecord) throws {
        saves += 1
        if failSaves { throw LicenseError.storage }
        self.record = record
    }
    func remove() throws {
        if let removalError { throw removalError }
        if failRemoval { throw LicenseError.storage }
        record = nil
    }
}

private actor LicenseServer: LicenseServing {
    var replies: [Result<PolarLicense, LicenseError>]
    var activationFailure: LicenseError?
    var removalFailure: LicenseError?
    var validationKeys: [String] = []
    var validationIDs: [UUID?] = []
    var activationCalls = 0
    var removalCalls = 0
    init(_ replies: [Result<PolarLicense, LicenseError>] = [.success(granted())]) { self.replies = replies }
    func configure(_ replies: [Result<PolarLicense, LicenseError>]) { self.replies = replies }
    func failActivation() { activationFailure = .activationLimit }
    func failRemoval() { removalFailure = .unavailable }
    func validate(key: String, activationID: UUID?) async throws -> PolarLicense {
        validationKeys.append(key); validationIDs.append(activationID)
        return try (replies.count > 1 ? replies.removeFirst() : replies[0]).get()
    }
    func activate(key: String) async throws -> UUID {
        activationCalls += 1
        if let activationFailure { throw activationFailure }
        return activationID
    }
    func deactivate(key: String, activationID: UUID) async throws {
        removalCalls += 1
        if let removalFailure { throw removalFailure }
    }
}

@Suite @MainActor struct LicenseStoreTests {
    @Test func startsLockedAndRejectsEmptyInputWithoutRequest() async {
        let server = LicenseServer()
        let store = LicenseStore(storage: MemoryLicenseStorage(), client: server)
        #expect(!store.isUnlocked)
        await store.activate(" \n ")
        #expect(!store.isUnlocked && store.errorMessage != nil)
        #expect(await server.validationKeys.isEmpty)
    }

    @Test func unlimitedLicenseValidatesWithoutAllocatingADeviceAndRestoresFromStorage() async {
        let storage = MemoryLicenseStorage()
        let server = LicenseServer()
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.activate("  TEST-KEY\n")
        #expect(store.isUnlocked && store.hasSavedLicense)
        #expect(storage.record?.key == "TEST-KEY")
        #expect(store.maskedKey == "••••–-KEY")
        #expect(await server.validationKeys == ["TEST-KEY"])
        #expect(await server.activationCalls == 0)
        let relaunched = LicenseStore(storage: storage, client: server, clock: { licenseTime.addingTimeInterval(100) })
        #expect(relaunched.isUnlocked)
    }

    @Test func deviceLimitedLicenseAllocatesOnceAndValidatesThatAllocation() async {
        let storage = MemoryLicenseStorage()
        let server = LicenseServer([.success(granted(limit: 2)), .success(granted(limit: 2, activation: activationID))])
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.activate("TEST-KEY")
        #expect(store.isUnlocked)
        #expect(storage.record?.activationID == activationID)
        #expect(storage.saves == 2)
        await store.recheck()
        #expect(await server.activationCalls == 1)
        #expect(await server.validationIDs == [nil, activationID, activationID])
    }

    @Test func lostValidationResponseRetainsAllocationForRetryWithoutUnlocking() async {
        let storage = MemoryLicenseStorage()
        let server = LicenseServer([.success(granted(limit: 1)), .failure(.unavailable)])
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.activate("TEST-KEY")
        #expect(!store.isUnlocked && store.hasSavedLicense)
        #expect(storage.record?.activationID == activationID && storage.record?.validatedAt == nil)
        await server.configure([.success(granted(limit: 1, activation: activationID))])
        await store.recheck()
        #expect(store.isUnlocked)
        #expect(await server.activationCalls == 1)
    }

    @Test func anotherProductCannotUnlockOrAllocateADevice() async {
        let server = LicenseServer([.success(granted(limit: 1, benefit: UUID()))])
        let store = LicenseStore(storage: MemoryLicenseStorage(), client: server)
        await store.activate("WRONG-PRODUCT")
        #expect(!store.isUnlocked && !store.hasSavedLicense)
        #expect(await server.activationCalls == 0)
    }

    @Test func offlineCacheIsBoundedAndCannotBypassExpiryOrClockRollback() {
        let record = LicenseRecord(key: "TEST", validatedAt: licenseTime)
        #expect(record.allowsUse(at: licenseTime.addingTimeInterval(6 * 86400)))
        #expect(!record.allowsUse(at: licenseTime.addingTimeInterval(7 * 86400)))
        #expect(!record.allowsUse(at: licenseTime.addingTimeInterval(-600)))
        let expired = LicenseRecord(key: "TEST", validatedAt: licenseTime, expiresAt: licenseTime.addingTimeInterval(60))
        #expect(!expired.allowsUse(at: licenseTime.addingTimeInterval(60)))
        #expect(!LicenseRecord(key: "TEST").allowsUse(at: licenseTime))
    }

    @Test func networkFailurePreservesOnlyPreviouslyVerifiedAccess() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", validatedAt: licenseTime))
        let server = LicenseServer([.failure(.unavailable)])
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime.addingTimeInterval(3600) })
        await store.recheck()
        #expect(store.isUnlocked && store.notice != nil)
        #expect(storage.record?.validatedAt == licenseTime)
        let expired = LicenseStore(storage: storage, client: server, clock: { licenseTime.addingTimeInterval(8 * 86400) })
        await expired.recheck()
        #expect(!expired.isUnlocked)
    }

    @Test func revocationInvalidatesCacheIncludingAfterRelaunch() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", validatedAt: licenseTime))
        let server = LicenseServer([.failure(.invalidKey)])
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.recheck()
        #expect(!store.isUnlocked && storage.record?.rejected == true)
        #expect(!LicenseStore(storage: storage, client: server, clock: { licenseTime }).isUnlocked)
    }

    @Test func deviceLimitDoesNotUnlock() async {
        let server = LicenseServer([.success(granted(limit: 1))])
        await server.failActivation()
        let store = LicenseStore(storage: MemoryLicenseStorage(), client: server)
        await store.activate("TEST")
        #expect(!store.isUnlocked && !store.hasSavedLicense && store.errorMessage != nil)
    }

    @Test func keychainFailureRollsBackNewDeviceAllocation() async {
        let storage = MemoryLicenseStorage()
        storage.failSaves = true
        let server = LicenseServer([.success(granted(limit: 1))])
        let store = LicenseStore(storage: storage, client: server)
        await store.activate("TEST")
        #expect(!store.isUnlocked && !store.hasSavedLicense)
        #expect(await server.removalCalls == 1)
    }

    @Test func failedDeactivationKeepsRecordForRetry() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", activationID: activationID, validatedAt: licenseTime))
        let server = LicenseServer()
        await server.failRemoval()
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.remove()
        #expect(store.isUnlocked && store.hasSavedLicense)
    }

    @Test func successfulDeactivationLocksEvenIfLocalDeletionFails() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", activationID: activationID, validatedAt: licenseTime))
        storage.failRemoval = true
        let store = LicenseStore(storage: storage, client: LicenseServer(), clock: { licenseTime })
        await store.remove()
        #expect(!store.isUnlocked && storage.record?.rejected == true)
    }

    @Test func removalShowsActualKeychainFailureAndCanRetry() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", validatedAt: licenseTime))
        storage.removalError = .keychain(operation: "remove", status: -25308)
        let store = LicenseStore(storage: storage, client: LicenseServer(), clock: { licenseTime })
        await store.remove()
        #expect(store.hasSavedLicense)
        #expect(store.errorMessage?.contains("-25308") == true)
        #expect(store.errorMessage?.contains("couldn’t save") != true)
        storage.removalError = nil
        await store.remove()
        #expect(!store.hasSavedLicense && !store.isUnlocked && store.errorMessage == nil)
    }

    @Test func removalReleasesDeviceAndDeletesKey() async {
        let storage = MemoryLicenseStorage(LicenseRecord(key: "TEST", activationID: activationID, validatedAt: licenseTime))
        let server = LicenseServer()
        let store = LicenseStore(storage: storage, client: server, clock: { licenseTime })
        await store.remove()
        #expect(!store.isUnlocked && !store.hasSavedLicense && storage.record == nil)
        #expect(await server.removalCalls == 1)
    }
}

private actor LicenseTransportStub: LicenseHTTPTransport {
    let status: Int
    let body: Data
    var request: URLRequest?
    init(status: Int = 200, body: Data) { self.status = status; self.body = body }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        return (body, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}

private func licenseJSON(expiry: String? = nil, benefit: UUID = WakeBeeLicense.benefitID, activation: UUID? = nil) throws -> Data {
    var json: [String: Any] = ["id": licenseID.uuidString,
                              "organization_id": WakeBeeLicense.organizationID.uuidString,
                              "benefit_id": benefit.uuidString, "status": "granted",
                              "expires_at": expiry.map { $0 as Any } ?? NSNull()]
    if let activation { json["activation"] = ["id": activation.uuidString, "license_key_id": licenseID.uuidString] }
    return try JSONSerialization.data(withJSONObject: json)
}

@Suite struct PolarLicenseClientTests {
    @Test func activationUsesWakeBeeLabelAndRetainsPolarIdentity() async throws {
        let license = try JSONSerialization.jsonObject(with: licenseJSON())
        let response: [String: Any] = ["id": activationID.uuidString,
                                      "license_key_id": licenseID.uuidString, "license_key": license]
        let transport = LicenseTransportStub(body: try JSONSerialization.data(withJSONObject: response))
        let result = try await PolarLicenseClient(transport: transport).activate(key: "TEST")
        #expect(result == activationID)
        let request = try #require(await transport.request)
        #expect(request.url?.absoluteString == "https://api.polar.sh/v1/customer-portal/license-keys/activate")
        let body = try #require(try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: String])
        #expect(body["label"] == "WakeBee on Mac")
        #expect(body["organization_id"] == WakeBeeLicense.organizationID.uuidString.lowercased())
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test(arguments: [204, 404])
    func removalUsesSavedPolarActivation(_ status: Int) async throws {
        let transport = LicenseTransportStub(status: status, body: Data())
        try await PolarLicenseClient(transport: transport).deactivate(key: "TEST", activationID: activationID)
        let request = try #require(await transport.request)
        #expect(request.url?.absoluteString == "https://api.polar.sh/v1/customer-portal/license-keys/deactivate")
        let body = try #require(try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: String])
        #expect(body["activation_id"] == activationID.uuidString.lowercased())
    }

    @Test func validationUsesPublicEndpointAndPinsWakeBeeBenefitWithoutSecrets() async throws {
        let transport = LicenseTransportStub(body: try licenseJSON(activation: activationID))
        _ = try await PolarLicenseClient(transport: transport).validate(key: "TEST", activationID: activationID)
        let request = try #require(await transport.request)
        #expect(request.url?.absoluteString == "https://api.polar.sh/v1/customer-portal/license-keys/validate")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        let body = try #require(try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: String])
        #expect(body["organization_id"] == WakeBeeLicense.organizationID.uuidString.lowercased())
        #expect(body["benefit_id"] == WakeBeeLicense.benefitID.uuidString.lowercased())
        #expect(body["activation_id"] == activationID.uuidString.lowercased())
        #expect(body["increment_usage"] == nil)
    }

    @Test func refusesSuccessForWrongProductOrWrongActivation() async throws {
        let wrongProduct = PolarLicenseClient(transport: LicenseTransportStub(body: try licenseJSON(benefit: UUID())))
        await #expect(throws: LicenseError.self) { try await wrongProduct.validate(key: "TEST", activationID: nil) }
        let wrongActivation = PolarLicenseClient(transport: LicenseTransportStub(body: try licenseJSON(activation: UUID())))
        await #expect(throws: LicenseError.self) { try await wrongActivation.validate(key: "TEST", activationID: activationID) }
    }

    @Test(arguments: ["2099-01-01T00:00:00Z", "2099-01-01T00:00:00.000000Z"])
    func supportsPolarExpiryFormats(_ expiry: String) async throws {
        let client = PolarLicenseClient(transport: LicenseTransportStub(body: try licenseJSON(expiry: expiry)))
        let result = try await client.validate(key: "TEST", activationID: nil)
        #expect(result.expiresAt != nil)
    }

    @Test(arguments: ["not-a-date", "2020-01-01T00:00:00Z"])
    func malformedOrExpiredDateDoesNotBecomePerpetual(_ expiry: String) async throws {
        let client = PolarLicenseClient(transport: LicenseTransportStub(body: try licenseJSON(expiry: expiry)))
        await #expect(throws: LicenseError.self) { try await client.validate(key: "TEST", activationID: nil) }
    }

    @Test(arguments: [302, 403, 404, 422, 429, 500])
    func nonSuccessNeverUnlocks(_ status: Int) async throws {
        let client = PolarLicenseClient(transport: LicenseTransportStub(status: status, body: try licenseJSON()))
        await #expect(throws: LicenseError.self) { try await client.validate(key: "TEST", activationID: nil) }
    }
}
