import Foundation

enum AppError: LocalizedError {
    case validation(String)
    case network(NetworkError)
    case service(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case let .validation(message):
            message
        case let .network(error):
            error.errorDescription
        case let .service(message):
            message
        case .unknown:
            "Ocurrió un error inesperado."
        }
    }
}
