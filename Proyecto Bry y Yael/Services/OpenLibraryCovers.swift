import Foundation

// Tamaños que ofrece la Covers API de Open Library.
nonisolated enum CoverSize: String {
    case small = "S"   // miniatura
    case medium = "M"  // tarjetas de la lista
    case large = "L"   // pantalla de detalle
}

// Construye las URLs de las portadas a partir del campo `cover_i` de la búsqueda.
// Documentación: https://openlibrary.org/dev/docs/api/covers
nonisolated enum OpenLibraryCovers {

    static let baseURL = "https://covers.openlibrary.org/b/id/"

    // `default=false` hace que el servidor responda 404 si la portada no existe,
    // en lugar de una imagen en blanco. Así AsyncImage entra en su estado de error
    // y la app muestra la portada de respaldo de BYbooKS.
    static func url(coverID: Int?, size: CoverSize) -> URL? {
        guard let coverID, coverID > 0 else {
            return nil
        }
        return URL(string: "\(baseURL)\(coverID)-\(size.rawValue).jpg?default=false")
    }
}
