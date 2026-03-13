import Foundation

final class URLSessionAPIClient: APIClient {
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let iso8601FormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private let requestBuilder: URLRequestBuilder
    private let session: URLSession
    private let decoder: JSONDecoder
    private let cacheStore: LocalResponseCache
    private let retryPolicy: RetryPolicy

    init(
        baseURL: URL,
        session: URLSession,
        decoder: JSONDecoder = JSONDecoder(),
        cacheStore: LocalResponseCache,
        retryPolicy: RetryPolicy = .basic
    ) {
        self.requestBuilder = URLRequestBuilder(baseURL: baseURL)
        self.session = session
        self.decoder = decoder
        self.cacheStore = cacheStore
        self.retryPolicy = retryPolicy

        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = Self.iso8601FormatterWithFractionalSeconds.date(from: value) {
                return date
            }

            if let date = Self.iso8601Formatter.date(from: value) {
                return date
            }

            if let date = Self.dateOnlyFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported BCRA date format: \(value)"
            )
        }
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        if case .cacheFirst = request.cachePolicy,
           let cachedData = await cacheStore.data(for: request.cacheKey),
           let decoded = try? decoder.decode(Response.self, from: cachedData) {
            return decoded
        }

        do {
            let data = try await performRequest(request)

            if let ttl = request.cachePolicy.ttl {
                await cacheStore.insert(data, for: request.cacheKey, ttl: ttl)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw NetworkError.decoding(error)
            }
        } catch let error as NetworkError {
            if case .networkWithCacheFallback = request.cachePolicy,
               let cachedData = await cacheStore.data(for: request.cacheKey),
               let decoded = try? decoder.decode(Response.self, from: cachedData) {
                return decoded
            }

            throw AppError.network(error)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown
        }
    }

    private func performRequest<Response>(_ request: APIRequest<Response>) async throws -> Data {
        var lastError: NetworkError?

        for attempt in 0...retryPolicy.maxRetries {
            do {
                let urlRequest = try requestBuilder.build(for: request)
                let (data, response) = try await session.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpStatus(httpResponse.statusCode)
                }

                return data
            } catch let error as NetworkError {
                lastError = error

                guard attempt < retryPolicy.maxRetries, error.isRetriable else {
                    break
                }

                try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds)
            } catch {
                let networkError = NetworkError.transport(error)
                lastError = networkError

                guard attempt < retryPolicy.maxRetries, networkError.isRetriable else {
                    break
                }

                try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds)
            }
        }

        throw lastError ?? .invalidResponse
    }
}
