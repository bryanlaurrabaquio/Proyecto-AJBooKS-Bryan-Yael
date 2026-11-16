import Foundation

// Limpieza de los textos que llegan de Open Library.
// Se aplica una sola vez, al convertir el JSON al modelo de la app, para que ninguna vista
// tenga que repetir esta lógica.
//
// Qué corrige:
//   - Texto con codificación incorrecta ("CorazÃ³n" -> "Corazón").
//   - Entidades HTML visibles ("&amp;", "&quot;", "&#39;").
//   - Etiquetas HTML literales ("<p>", "<br>", "<i>").
//   - Marcas de Markdown (*cursiva*, **negrita**, [enlace](url), referencias "[1]: https://...").
//   - Caracteres invisibles, de control y de reemplazo (U+FFFD).
//   - Espacios, tabulaciones y saltos de línea excesivos.
//
// Qué NO toca: acentos, ñ, ¿ ¡, comillas tipográficas, guiones y demás caracteres legítimos.
nonisolated enum TextSanitizer {

    // MARK: - Funciones públicas

    // Para títulos, autores y géneros: el resultado ocupa una sola línea.
    static func cleanInline(_ text: String) -> String {
        var result = prepare(text)
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return finish(result)
    }

    // Para títulos: además quita la puntuación de catálogo que a veces queda al final
    // ("La Odisea." -> "La Odisea", "El castillo /" -> "El castillo").
    static func cleanTitle(_ text: String) -> String {
        var title = cleanInline(text)

        title = title.replacingOccurrences(
            of: "\\s*[/:;=,]+$",
            with: "",
            options: .regularExpression
        )

        // Un punto final suelto se quita, pero no los puntos suspensivos,
        // las abreviaturas cortas ("Jr."), las iniciales ("S.A.") ni "etc.".
        if title.hasSuffix(".") && !title.hasSuffix("..") {
            let withoutDot = String(title.dropLast())
            let lastWord = withoutDot.split(separator: " ").last.map(String.init) ?? ""
            let isShortAbbreviation = lastWord.allSatisfy { $0.isLetter } && lastWord.count < 3
            let isInitials = lastWord.contains(".")
            let isEtc = lastWord.lowercased() == "etc"
            if !lastWord.isEmpty && !isShortAbbreviation && !isInitials && !isEtc {
                title = withoutDot
            }
        }

        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Para descripciones: conserva los párrafos, pero elimina el formato y los espacios sobrantes.
    static func cleanParagraphs(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n\n")

        // Saltos de línea de HTML antes de quitar las etiquetas.
        result = result.replacingOccurrences(
            of: "(?i)<br\\s*/?>|</p\\s*>|</div\\s*>|</li\\s*>",
            with: "\n",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "(?i)<li[^<>]*>",
            with: "• ",
            options: .regularExpression
        )

        result = prepare(result)
        result = removeMarkdown(result)

        // Espacios horizontales repetidos (incluye espacios duros U+00A0) -> un espacio.
        result = result.replacingOccurrences(of: "[\\t\\p{Zs}]+", with: " ", options: .regularExpression)
        // Espacios al inicio y al final de cada línea.
        result = result.replacingOccurrences(of: "(?m)^ +| +$", with: "", options: .regularExpression)
        // Más de una línea en blanco seguida -> un solo cambio de párrafo.
        result = result.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)

        return finish(result)
    }

    // MARK: - Pasos comunes

    private static func prepare(_ text: String) -> String {
        var result = repairMojibake(text)
        result = decodeHTMLEntities(result)
        result = stripHTMLTags(result)
        result = removeInvisibleCharacters(result)
        return result
    }

    private static func finish(_ text: String) -> String {
        // NFC: une letras y acentos que llegan separados ("a" + "´" -> "á").
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
    }

    // MARK: - Codificación

    // Detecta texto UTF-8 que fue leído como Windows-1252/Latin-1 ("canciÃ³n", "Â¿", "â€œ")
    // y lo vuelve a decodificar. Solo se acepta el resultado si es UTF-8 válido y
    // realmente reduce las secuencias extrañas; si no, se deja el texto original.
    static func repairMojibake(_ text: String) -> String {
        let originalScore = mojibakeScore(text)
        guard originalScore > 0 else {
            return text
        }

        for encoding in [String.Encoding.windowsCP1252, .isoLatin1] {
            if let bytes = text.data(using: encoding),
               let repaired = String(data: bytes, encoding: .utf8),
               mojibakeScore(repaired) < originalScore {
                return repaired
            }
        }

        return text
    }

    private static func mojibakeScore(_ text: String) -> Int {
        let pattern = "Ã[\\u0080-\\u00BF\\u0152\\u0153\\u0160\\u0161\\u0178\\u017D\\u017E\\u0192\\u02C6\\u02DC\\u2013\\u2014\\u2018-\\u201E\\u2020-\\u2022\\u2026\\u2030\\u2039\\u203A\\u20AC\\u2122]|Â[\\u00A0-\\u00BF]|â€"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return 0
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.numberOfMatches(in: text, range: range)
    }

    // MARK: - HTML

    static func stripHTMLTags(_ text: String) -> String {
        // Solo etiquetas reales: "<" seguido de una letra o "/". Así "1 < 2" no se modifica.
        text.replacingOccurrences(
            of: "</?[A-Za-z][^<>]*>",
            with: "",
            options: .regularExpression
        )
    }

    // Convierte entidades como "&amp;", "&#233;" o "&#xE9;" en su carácter.
    // Se hacen hasta dos pasadas para cubrir textos codificados dos veces ("&amp;quot;").
    static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        for _ in 0..<2 {
            guard result.contains("&") else { break }
            let decoded = decodeEntitiesOnce(result)
            if decoded == result { break }
            result = decoded
        }
        return result
    }

    private static func decodeEntitiesOnce(_ text: String) -> String {
        var result = ""
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character == "&",
               let semicolon = text[index...].prefix(12).firstIndex(of: ";") {
                let name = String(text[text.index(after: index)..<semicolon])
                if let decoded = decodeEntity(name) {
                    result.append(decoded)
                    index = text.index(after: semicolon)
                    continue
                }
            }

            result.append(character)
            index = text.index(after: index)
        }

        return result
    }

    private static func decodeEntity(_ name: String) -> String? {
        if name.hasPrefix("#") {
            let digits = name.dropFirst()
            let value: UInt32?
            if digits.first == "x" || digits.first == "X" {
                value = UInt32(digits.dropFirst(), radix: 16)
            } else {
                value = UInt32(digits, radix: 10)
            }
            guard let value, let scalar = Unicode.Scalar(value) else {
                return nil
            }
            return String(Character(scalar))
        }

        return namedEntities[name]
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "shy": "\u{00AD}",
        "hellip": "…", "mdash": "—", "ndash": "–", "bull": "•", "middot": "·",
        "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”", "laquo": "«", "raquo": "»",
        "iexcl": "¡", "iquest": "¿", "ordm": "º", "ordf": "ª", "deg": "°",
        "copy": "©", "reg": "®", "trade": "™", "euro": "€",
        "aacute": "á", "eacute": "é", "iacute": "í", "oacute": "ó", "uacute": "ú",
        "Aacute": "Á", "Eacute": "É", "Iacute": "Í", "Oacute": "Ó", "Uacute": "Ú",
        "ntilde": "ñ", "Ntilde": "Ñ", "uuml": "ü", "Uuml": "Ü", "ccedil": "ç", "Ccedil": "Ç",
        "agrave": "à", "egrave": "è", "igrave": "ì", "ograve": "ò", "ugrave": "ù",
        "acirc": "â", "ecirc": "ê", "icirc": "î", "ocirc": "ô", "ucirc": "û",
        "auml": "ä", "euml": "ë", "iuml": "ï", "ouml": "ö", "Auml": "Ä", "Ouml": "Ö",
        "atilde": "ã", "otilde": "õ", "aring": "å", "oslash": "ø", "aelig": "æ", "szlig": "ß"
    ]

    // MARK: - Markdown

    private static func removeMarkdown(_ text: String) -> String {
        let rules: [(pattern: String, template: String)] = [
            // Definiciones de referencias: "[1]: https://es.wikipedia.org/..."
            ("(?m)^[ \\t]*\\[[^\\]\\n]+\\]:[ \\t]*\\S+.*$", ""),
            // Imágenes: ![texto](url)
            ("!\\[[^\\]\\n]*\\]\\([^)\\n]*\\)", ""),
            // Enlaces: [texto](url) y [texto][1] -> texto
            ("\\[([^\\]\\n]+)\\]\\([^)\\n]*\\)", "$1"),
            ("\\[([^\\]\\n]+)\\]\\[[^\\]\\n]*\\]", "$1"),
            // Énfasis: ***texto***, **texto**, *texto*, __texto__ -> texto
            ("(\\*{1,3}|_{2})(?=\\S)([^\\n]+?)(?<=\\S)\\1", "$2"),
            // Encabezados (# Título) y citas (> texto)
            ("(?m)^[ \\t]*#{1,6}[ \\t]+", ""),
            ("(?m)^[ \\t]*>[ \\t]?", ""),
            // Separadores horizontales: ---, ***, ___
            ("(?m)^[ \\t]*([-*_])([ \\t]*\\1){2,}[ \\t]*$", ""),
            // Viñetas de lista -> "• "
            ("(?m)^[ \\t]*[-*+][ \\t]+", "• "),
            // Caracteres escapados: \* \_ \[ ...
            ("\\\\([\\\\`*_{}\\[\\]()#+.!-])", "$1")
        ]

        var result = text
        for rule in rules {
            result = result.replacingOccurrences(
                of: rule.pattern,
                with: rule.template,
                options: .regularExpression
            )
        }
        return result
    }

    // MARK: - Caracteres invisibles

    private static let invisibleScalars: Set<UInt32> = [
        0x200B, // espacio de ancho cero
        0x2060, // unión de palabras
        0xFEFF, // marca de orden de bytes
        0x00AD, // guion suave
        0xFFFD  // carácter de reemplazo (texto dañado)
    ]

    static func removeInvisibleCharacters(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if invisibleScalars.contains(scalar.value) {
                continue
            }
            // Caracteres de control: se conservan el salto de línea y la tabulación;
            // los demás que separan palabras ("\r", tabulación vertical) pasan a ser un espacio
            // y el resto se elimina.
            if scalar.properties.generalCategory == .control && scalar != "\n" && scalar != "\t" {
                if scalar.properties.isWhitespace {
                    scalars.append(" ")
                }
                continue
            }
            scalars.append(scalar)
        }
        return String(scalars)
    }
}
