import Foundation

public protocol LicenseHTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Never forwards a license key through an HTTP redirect, cookie jar, or disk cache.
private final class LicenseTransport: NSObject, LicenseHTTPTransport, URLSessionTaskDelegate, @unchecked Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, data.count <= 256 * 1024 else {
            throw LicenseError.invalidResponse
        }
        return (data, response)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

public struct PolarLicenseClient: LicenseServing {
    private let transport: any LicenseHTTPTransport
    public init(transport: (any LicenseHTTPTransport)? = nil) { self.transport = transport ?? LicenseTransport() }

    public func validate(key: String, activationID: UUID?) async throws -> PolarLicense {
        var body = commonBody(key)
        body["benefit_id"] = WakeBeeLicense.benefitID.uuidString.lowercased()
        body["activation_id"] = activationID?.uuidString.lowercased()
        let data = try await request("validate", body: body)
        let license: PolarLicense = try decode(data)
        try license.check(activationID: activationID)
        return license
    }

    public func activate(key: String) async throws -> UUID {
        var body = commonBody(key)
        // A generic label avoids sending a person's computer name or hardware identifiers.
        body["label"] = "WakeBee on Mac"
        let data = try await request("activate", body: body)
        struct Response: Decodable {
            let id: UUID
            let licenseKeyID: UUID
            let license: PolarLicense
            enum CodingKeys: String, CodingKey { case id; case licenseKeyID = "license_key_id", license = "license_key" }
        }
        let response: Response = try decode(data)
        try response.license.check()
        guard response.license.id == response.licenseKeyID else { throw LicenseError.invalidResponse }
        return response.id
    }

    public func deactivate(key: String, activationID: UUID) async throws {
        var body = commonBody(key)
        body["activation_id"] = activationID.uuidString.lowercased()
        _ = try await request("deactivate", body: body)
    }

    private func commonBody(_ key: String) -> [String: String] {
        ["key": key, "organization_id": WakeBeeLicense.organizationID.uuidString.lowercased()]
    }

    private func request(_ action: String, body: [String: String]) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://api.polar.sh/v1/customer-portal/license-keys/\(action)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)
        let result: (Data, HTTPURLResponse)
        do { result = try await transport.send(request) }
        catch let error as LicenseError { throw error }
        catch { throw LicenseError.unavailable }
        switch result.1.statusCode {
        case 200 where action != "deactivate": return result.0
        case 204 where action == "deactivate": return result.0
        case 404 where action == "deactivate": return Data() // Already revoked/removed remotely.
        case 403 where action == "activate": throw LicenseError.activationLimit
        case 400, 401, 403, 404, 422: throw LicenseError.invalidKey
        case 408, 429, 500...599: throw LicenseError.unavailable
        default: throw LicenseError.invalidResponse
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid expiry date")
            }
            return date
        }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw LicenseError.invalidResponse }
    }
}
