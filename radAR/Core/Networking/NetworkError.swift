import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case transport(Error)
    case decoding(Error)

    var isRetriable: Bool {
        switch self {
        case .invalidURL, .decoding:
            false
        case .invalidResponse, .transport:
            true
        case let .httpStatus(code):
            (500...599).contains(code)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "No pudimos armar la URL de la consulta."
        case .invalidResponse:
            "El servidor respondió de una forma inesperada."
        case let .httpStatus(code):
            "La consulta devolvió un estado HTTP \(code)."
        case let .transport(error):
            "Fallo de red: \(error.localizedDescription)"
        case let .decoding(error):
            "No pudimos interpretar la respuesta del servidor: \(error.localizedDescription)"
        }
    }
}
