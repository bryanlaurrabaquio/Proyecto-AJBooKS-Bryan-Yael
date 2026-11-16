import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

// Detecta el idioma de una descripción para no presentar un texto en inglés
// como si fuera la sinopsis en español.
// En iOS usa el framework NaturalLanguage de Apple: funciona en el dispositivo,
// sin red, sin credenciales y sin costo.
nonisolated enum LanguageDetector {

    static let spanishCode = "es"

    // Devuelve el código ISO 639-1 del idioma dominante ("es", "en", ...) o nil si no se puede saber.
    static func languageCode(of text: String) -> String? {
        let sample = String(text.prefix(1000))
        guard sample.contains(where: { $0.isLetter }) else {
            return nil
        }

        #if canImport(NaturalLanguage)
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sample)
        guard let language = recognizer.dominantLanguage, language != .undetermined else {
            return nil
        }
        return language.rawValue
        #else
        return heuristicLanguageCode(of: sample)
        #endif
    }

    // Respaldo para plataformas sin NaturalLanguage (por ejemplo, al compilar la lógica en Linux):
    // cuenta palabras muy frecuentes de cada idioma.
    static func heuristicLanguageCode(of text: String) -> String? {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else {
            return nil
        }

        var scores: [String: Int] = [:]
        for word in words {
            for (code, list) in stopwords where list.contains(word) {
                scores[code, default: 0] += 1
            }
        }

        // Signos exclusivos del español.
        if text.contains("¿") || text.contains("¡") || text.contains("ñ") {
            scores[spanishCode, default: 0] += 3
        }

        let ranked = scores.sorted { $0.value > $1.value }
        guard let best = ranked.first, best.value >= 2 else {
            return nil
        }
        if ranked.count > 1 && ranked[1].value == best.value {
            return nil
        }
        return best.key
    }

    private static let stopwords: [String: Set<String>] = [
        "es": ["el", "la", "los", "las", "del", "que", "y", "una", "por", "con", "para",
               "su", "sus", "es", "se", "lo", "como", "más", "pero", "este", "esta", "entre",
               "cuando", "muy", "sin", "sobre", "también", "hasta", "donde", "quien", "desde"],
        "en": ["the", "of", "and", "to", "is", "that", "it", "was", "for", "on", "are",
               "with", "his", "her", "they", "at", "be", "this", "from", "have", "by",
               "which", "their", "who", "has", "an", "were", "when", "she", "he"],
        "fr": ["le", "les", "des", "est", "et", "une", "dans", "qui", "pour", "pas", "sur",
               "au", "avec", "il", "elle", "ce", "aux", "du", "sont"],
        "de": ["der", "die", "das", "und", "ist", "nicht", "mit", "ein", "eine", "zu",
               "den", "von", "sich", "auf", "dem", "auch", "wird"],
        "pt": ["os", "as", "não", "uma", "com", "para", "um", "do", "da", "dos", "das",
               "ao", "pela", "pelo", "também", "ele", "ela", "é"]
    ]

    // Nombre del idioma en español para mostrarlo en la interfaz ("en" -> "inglés").
    static func spanishName(forLanguageCode code: String?) -> String {
        guard let code else {
            return "otro idioma"
        }

        let base = code.split(separator: "-").first.map(String.init) ?? code

        if let known = knownNames[base] {
            return known
        }

        if let name = Locale(identifier: "es").localizedString(forLanguageCode: base) {
            return name.lowercased()
        }

        return "otro idioma"
    }

    private static let knownNames: [String: String] = [
        "en": "inglés", "fr": "francés", "de": "alemán", "it": "italiano",
        "pt": "portugués", "ru": "ruso", "la": "latín", "el": "griego",
        "ca": "catalán", "nl": "neerlandés", "ja": "japonés", "zh": "chino"
    ]
}
