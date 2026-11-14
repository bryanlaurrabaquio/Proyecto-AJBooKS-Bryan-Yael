import Foundation

// Solo conserva los datos que la app realmente usa:
// el código HTTP se muestra en el mensaje; los demás casos no necesitan valor.
enum BookServiceError: Error, Equatable {
    case invalidURL
    case connectivity
    case invalidResponse
    case httpStatus(Int)
    case decoding
    case unknown
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
}
