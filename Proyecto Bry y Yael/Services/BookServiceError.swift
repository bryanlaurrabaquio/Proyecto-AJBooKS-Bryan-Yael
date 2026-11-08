import Foundation

enum BookServiceError: Error, Equatable {
    case invalidURL
    case connectivity(URLError.Code)
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case unknown(String)
}

extension BookServiceError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "No se pudo preparar la consulta."

        case .connectivity:
            return "No hay conexión con Open Library."

        case .invalidResponse:
            return "La respuesta del servidor es inválida."

        case .httpStatus(let code):
            return "Error del servidor. Código HTTP: \(code)"

        case .decoding:
            return "No se pudieron interpretar los libros."

        case .unknown:
            return "Ocurrió un error inesperado."
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"

        case .connectivity(let code):
            return "URLError: \(code.rawValue)"

        case .invalidResponse:
            return "La respuesta no es HTTP"

        case .httpStatus(let code):
            return "HTTP \(code)"

        case .decoding(let detail):
            return detail

        case .unknown(let detail):
            return detail
        }
    }
}
