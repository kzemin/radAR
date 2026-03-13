import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum APICachePolicy {
    case none
    case cacheFirst(ttl: TimeInterval)
    case networkWithCacheFallback(ttl: TimeInterval)

    var ttl: TimeInterval? {
        switch self {
        case .none:
            nil
        case let .cacheFirst(ttl), let .networkWithCacheFallback(ttl):
            ttl
        }
    }
}

struct APIRequest<Response: Decodable> {
    let path: String
    var method: HTTPMethod
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var body: Data?
    var cachePolicy: APICachePolicy

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        cachePolicy: APICachePolicy = .none
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
    }

    var cacheKey: String {
        let query = queryItems
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")

        return "\(method.rawValue):\(path)?\(query)"
    }
}
