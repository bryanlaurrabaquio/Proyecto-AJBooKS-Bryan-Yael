import Foundation

// Open Library no tiene un campo "género": entrega una lista libre de temas (`subject`)
// casi siempre en inglés y con formatos variados ("Fiction", "Science Fiction & Fantasy",
// "great_books_of_the_western_world", "Fiction, Romance, Historical, Regency").
//
// Este mapeo traduce SOLO categorías conocidas a un vocabulario controlado en español.
// No se traducen títulos ni nombres. Si ningún tema coincide, el género queda en nil
// y la interfaz no lo muestra (no se inventa un valor).
nonisolated enum SubjectGenreMapper {

    // Prioridad de cada categoría (el número menor gana).
    enum Tier: Int, Comparable {
        // Género literario: "Poesía", "Ciencia ficción", "Romance"...
        case literary = 0
        // Tema de no ficción: "Filosofía", "Historia"... Se ignora si la obra está marcada
        // como ficción, porque en una novela "Historia" describe el tema, no el género.
        case topic
        // Categoría amplia: "Ficción", "Clásicos", "Novela".
        case general
        // Público: "Infantil y juvenil". Muchas obras clásicas tienen ediciones juveniles,
        // por eso solo se usa si no hay nada mejor.
        case audience

        static func < (lhs: Tier, rhs: Tier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // Solo se revisan los primeros temas: Open Library los ordena por relevancia
    // y los últimos suelen ser muy específicos (lugares, personajes, etc.).
    static let maxSubjectsToInspect = 12

    static func spanishGenre(from subjects: [String]) -> String? {
        let inspected = subjects.prefix(maxSubjectsToInspect).map(candidates(for:))
        let isFiction = inspected.joined().contains(where: isFictionMarker)

        var best: (genre: String, tier: Tier)?

        for candidates in inspected {
            for candidate in candidates {
                guard let match = catalog[candidate] else {
                    continue
                }
                if match.tier == .topic && isFiction {
                    continue
                }
                if best == nil || match.tier < best!.tier {
                    best = match
                }
            }
        }

        return best?.genre
    }

    // Formas en que se compara un tema: completo y cada parte separada por comas o "/".
    // "Fiction, Romance, Historical" -> ["fiction romance historical", "fiction", "romance", "historical"]
    private static func candidates(for subject: String) -> [String] {
        let full = normalize(subject)
        let parts = subject
            .split(whereSeparator: { $0 == "," || $0 == "/" })
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty && $0 != full }
        return [full] + parts
    }

    private static func isFictionMarker(_ candidate: String) -> Bool {
        let words = candidate.split(separator: " ")
        return words.contains("fiction") || ["novela", "novel", "novels", "ficcion"].contains(candidate)
    }

    // Minúsculas, sin acentos y sin signos: "Ciencia-ficción" -> "ciencia ficcion".
    static func normalize(_ text: String) -> String {
        let cleaned = TextSanitizer.cleanInline(text)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "['’]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private static let catalog: [String: (genre: String, tier: Tier)] = {
        var result: [String: (genre: String, tier: Tier)] = [:]
        for (tier, table) in [(Tier.literary, literary), (.topic, topics), (.general, general), (.audience, audience)] {
            for (key, genre) in table {
                result[key] = (genre, tier)
            }
        }
        return result
    }()

    private static let literary: [String: String] = [
        // Ciencia ficción y fantasía
        "science fiction": "Ciencia ficción",
        "science fiction and fantasy": "Ciencia ficción",
        "ciencia ficcion": "Ciencia ficción",
        "fantasy": "Fantasía",
        "fantasy fiction": "Fantasía",
        "fantastique": "Fantasía",
        "fantasia": "Fantasía",
        "dystopias": "Distopía",
        "dystopian fiction": "Distopía",
        // Terror, misterio y suspenso
        "horror": "Terror",
        "horror tales": "Terror",
        "horror fiction": "Terror",
        "terror": "Terror",
        "gothic fiction": "Novela gótica",
        "mystery": "Misterio",
        "mystery fiction": "Misterio",
        "detective and mystery stories": "Misterio",
        "detective fiction": "Misterio",
        "misterio": "Misterio",
        "thriller": "Suspenso",
        "suspense": "Suspenso",
        // Romance y aventura
        "romance": "Romance",
        "love stories": "Romance",
        "adventure": "Aventura",
        "adventure stories": "Aventura",
        "action and adventure": "Aventura",
        "fiction action and adventure": "Aventura",
        "aventura": "Aventura",
        "historical fiction": "Novela histórica",
        "fiction historical": "Novela histórica",
        "psychological fiction": "Novela psicológica",
        "fiction psychological": "Novela psicológica",
        "satire": "Sátira",
        "humorous fiction": "Humor",
        // Poesía, teatro y otros géneros literarios
        // ("Drama" no se usa: en Open Library suele referirse a adaptaciones, no a obras de teatro).
        "poetry": "Poesía",
        "poesia": "Poesía",
        "epic poetry": "Poesía épica",
        "greek epic poetry": "Poesía épica",
        "theater": "Teatro",
        "plays": "Teatro",
        "teatro": "Teatro",
        "short stories": "Cuento",
        "cuentos": "Cuento",
        "essays": "Ensayo",
        "ensayo": "Ensayo",
        "allegories": "Alegoría",
        "alegorias": "Alegoría",
        "mythology": "Mitología",
        "greek mythology": "Mitología",
        "classical mythology": "Mitología",
        "mythology greek": "Mitología",
        "mythology classical": "Mitología",
        "mythologie": "Mitología"
    ]

    private static let topics: [String: String] = [
        "philosophy": "Filosofía",
        "philosophers": "Filosofía",
        "philosophie": "Filosofía",
        "filosofia": "Filosofía",
        "chinese philosophy": "Filosofía",
        "ethics": "Filosofía",
        "history": "Historia",
        "historia": "Historia",
        "biography": "Biografía",
        "autobiography": "Biografía",
        "biografia": "Biografía",
        "religion": "Religión",
        "psychology": "Psicología",
        "political science": "Política",
        "politics and government": "Política",
        "self help": "Autoayuda"
    ]

    private static let general: [String: String] = [
        "fiction": "Ficción",
        "fiction general": "Ficción",
        "literary fiction": "Ficción",
        "contemporary fiction": "Ficción",
        "literature and fiction": "Ficción",
        "ficcion": "Ficción",
        "novela": "Novela",
        "novel": "Novela",
        "novels": "Novela",
        "classic literature": "Clásicos",
        "classics": "Clásicos",
        "classical literature": "Clásicos",
        "fiction classics": "Clásicos",
        "literature classics": "Clásicos",
        "great books of the western world": "Clásicos",
        "clasicos": "Clásicos",
        "nonfiction": "No ficción"
    ]

    private static let audience: [String: String] = [
        "childrens fiction": "Infantil y juvenil",
        "childrens literature": "Infantil y juvenil",
        "childrens stories": "Infantil y juvenil",
        "juvenile fiction": "Infantil y juvenil",
        "juvenile literature": "Infantil y juvenil"
    ]
}
