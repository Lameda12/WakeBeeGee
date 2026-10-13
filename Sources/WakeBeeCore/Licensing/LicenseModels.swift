import Foundation

public enum WakeBeeLicense {
    // Public identifiers from WakeBee's Polar checkout. These are not API secrets.
    public static let purchaseURL = URL(string: "https://buy.polar.sh/polar_cl_HMkc1qGmstC5HhR91Tz3XMqlAbV2MLKp1JvyS2xPMrC")!
    public static let organizationID = UUID(uuidString: "3514b35c-f79b-4b3d-ac5d-02ea8fd79b7b")!
    public static let benefitID = UUID(uuidString: "7e82e3d3-ca74-4661-ba7f-8ab9f290148c")!
    public static let offlineAllowance: TimeInterval = 7 * 24 * 3600
    public static let validationInterval: TimeInterval = 24 * 3600
}

public struct LicenseRecord: Codable, Sendable {
    public let key: String
    public let organizationID: UUID
    public let benefitID: UUID
    public var activationID: UUID?
    public var validatedAt: Date?
    public var expiresAt: Date?
    public var rejected = false

    public init(key: String, activationID: UUID? = nil, validatedAt: Date? = nil, expiresAt: Date? = nil) {
        self.key = key
        organizationID = WakeBeeLicense.organizationID
        benefitID = WakeBeeLicense.benefitID
        self.activationID = activationID
        self.validatedAt = validatedAt
        self.expiresAt = expiresAt
    }

    public func allowsUse(at now: Date) -> Bool {
        guard organizationID == WakeBeeLicense.organizationID, benefitID == WakeBeeLicense.benefitID,
              !rejected, let validatedAt, validatedAt.timeIntervalSince(now) <= 300,
              now < validatedAt.addingTimeInterval(WakeBeeLicense.offlineAllowance) else { return false }
        return expiresAt.map { now < $0 } ?? true
    }
}

public struct PolarLicense: Decodable, Sendable {
    public let id: UUID
    public let organizationID: UUID
    public let benefitID: UUID
    public let status: String
    public let limitActivations: Int?
    public let expiresAt: Date?
    public let activation: Activation?

    public struct Activation: Decodable, Sendable {
        public let id: UUID
        public let licenseKeyID: UUID
        enum CodingKeys: String, CodingKey { case id; case licenseKeyID = "license_key_id" }
    }
    enum CodingKeys: String, CodingKey {
        case id, status, activation
        case organizationID = "organization_id", benefitID = "benefit_id"
        case limitActivations = "limit_activations", expiresAt = "expires_at"
    }

    public func check(activationID: UUID? = nil, at now: Date = .now) throws {
        guard organizationID == WakeBeeLicense.organizationID, benefitID == WakeBeeLicense.benefitID else {
            throw LicenseError.wrongProduct
        }
        guard status == "granted", expiresAt.map({ now < $0 }) ?? true else { throw LicenseError.invalidKey }
        if let activationID {
            guard activation?.id == activationID, activation?.licenseKeyID == id else { throw LicenseError.invalidKey }
        }
    }
}

public enum LicenseError: LocalizedError, Sendable {
    case emptyKey, invalidKey, wrongProduct, activationLimit, unavailable, invalidResponse, storage, cleanup

    case keychain(operation: String, status: Int32)

    public var isDefinitive: Bool {
        switch self {
        case .invalidKey, .wrongProduct: true
        default: false
        }
    }
    public var errorDescription: String? {
        switch self {
        case .emptyKey: "Enter the license key from your Polar purchase."
        case .invalidKey: "This license could not be verified. Check the key and its status in your Polar purchase."
        case .wrongProduct: "This key is for a different product. Enter a WakeBee license key."
        case .activationLimit: "This key could not be activated. Check its device limit and status in your Polar purchase."
        case .unavailable: "Couldn’t reach Polar. Check your internet connection and try again."
        case .invalidResponse: "Polar returned an unexpected response. Please try again later."
        case .storage: "Couldn’t update the saved license in macOS Keychain. Please try again."
        case let .keychain(operation, status):
            switch status {
            case -128: "Keychain access was cancelled. Try again and allow WakeBee access when macOS asks."
            case -25293: "macOS did not authorize WakeBee to \(operation) the saved license. Check Keychain access and try again. (\(status))"
            case -25308: "macOS could not show the Keychain access prompt. Unlock your Mac, reopen WakeBee, and try again. (\(status))"
            default: "Couldn’t \(operation) the saved license in macOS Keychain. Error \(status)."
            }
        case .cleanup: "Couldn’t save this activation or release it on Polar. Manage its devices in your Polar purchase before trying again."
        }
    }
}

@MainActor public protocol LicenseStorage {
    func load() throws -> LicenseRecord?
    func save(_ record: LicenseRecord) throws
    func remove() throws
}

public protocol LicenseServing: Sendable {
    func validate(key: String, activationID: UUID?) async throws -> PolarLicense
    func activate(key: String) async throws -> UUID
    func deactivate(key: String, activationID: UUID) async throws
}
