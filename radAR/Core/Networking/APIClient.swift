import Foundation

protocol APIClient {
    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response
}

struct RetryPolicy {
    let maxRetries: Int
    let delayNanoseconds: UInt64

    static let basic = RetryPolicy(
        maxRetries: 2,
        delayNanoseconds: 350_000_000
    )
}
