import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de la limpieza de texto que se aplica a los datos de Open Library.
// Los casos reproducen problemas reales encontrados en las respuestas de la API.
struct TextSanitizerTests {

    // MARK: - Una línea (títulos, autores, géneros)

    @Test(arguments: [
        ("Pride &amp; Prejudice", "Pride & Prejudice"),
        ("&quot;Hola&quot; &#39;mundo&#39; &#x27;x&#x27;", "\"Hola\" 'mundo' 'x'"),
        ("&iquest;Qu&eacute; pas&oacute;?", "¿Qué pasó?"),
        ("&amp;quot;Doble&amp;quot;", "\"Doble\""),
        ("<i>El</i> <b>Aleph</b>", "El Aleph"),
        ("Cien\u{00A0}años  de\tsoledad", "Cien años de soledad"),
        ("  Rayuela \n", "Rayuela"),
        ("Texto\u{FFFD} dañado", "Texto dañado"),
        ("Pala\u{200B}bra", "Palabra"),
        ("1 < 2", "1 < 2")
    ])
    func cleanInlineCorrigeTexto(entrada: String, esperado: String) {
        #expect(TextSanitizer.cleanInline(entrada) == esperado)
    }

    // Texto UTF-8 leído con la codificación equivocada.
    @Test(arguments: [
        ("CorazÃ³n delator", "Corazón delator"),
        ("Â¿DÃ³nde estÃ¡ el niÃ±o?", "¿Dónde está el niño?"),
        ("Lâ€™amour fou", "L’amour fou")
    ])
    func reparaTextoMalCodificado(entrada: String, esperado: String) {
        #expect(TextSanitizer.cleanInline(entrada) == esperado)
    }

    @Test func conservaCaracteresLegitimosDelEspanol() {
        let texto = "¡Ñandú! «Señor» — ¿sí? Pingüino, café y acción."
        #expect(TextSanitizer.cleanInline(texto) == texto)
    }

    @Test func noModificaTextoLatinoCorrectoConMayusculas() {
        // "SÃO" es portugués válido: no debe confundirse con texto mal codificado.
        #expect(TextSanitizer.cleanInline("SÃO PAULO") == "SÃO PAULO")
    }

    @Test func unificaAcentosSeparados() {
        // "a" + acento combinado -> "á" en un solo carácter (NFC).
        let resultado = TextSanitizer.cleanInline("Pedro Pa\u{0301}ramo")
        #expect(resultado == "Pedro Páramo")
        #expect(resultado.unicodeScalars.count == "Pedro Páramo".unicodeScalars.count)
    }

    // MARK: - Títulos

    @Test(arguments: [
        ("La Odisea.", "La Odisea"),
        ("El castillo /", "El castillo"),
        ("Ensayo sobre la ceguera :", "Ensayo sobre la ceguera"),
        ("París y Londres en 1793.", "París y Londres en 1793"),
        ("Ensayo sobre la ceguera...", "Ensayo sobre la ceguera..."),
        ("Cartas de Martin Luther King Jr.", "Cartas de Martin Luther King Jr."),
        ("¿Quién mató a Palomino Molero?", "¿Quién mató a Palomino Molero?")
    ])
    func cleanTitleQuitaPuntuacionDeCatalogo(entrada: String, esperado: String) {
        #expect(TextSanitizer.cleanTitle(entrada) == esperado)
    }

    // MARK: - Descripciones

    @Test func quitaReferenciasDeMarkdown() {
        // Formato real de Open Library (descripción de La Odisea).
        let entrada = "Poema épico griego. - [Wikipedia][1]\r\n\r\n  [1]: https://en.wikipedia.org/wiki/Odyssey"
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Poema épico griego. - Wikipedia")
    }

    @Test func quitaEnfasisDeMarkdown() {
        let entrada = "***Clásico suizo*** sobre **Heidi** y *Pedro*."
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Clásico suizo sobre Heidi y Pedro.")
    }

    @Test func convierteEnlacesEnTexto() {
        let entrada = "Ver [la reseña](https://example.com/resena) completa."
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Ver la reseña completa.")
    }

    @Test func conservaParrafosPeroQuitaLineasSobrantes() {
        let entrada = "Primer párrafo.\r\n\r\n\r\n\r\nSegundo   párrafo.  "
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Primer párrafo.\n\nSegundo párrafo.")
    }

    @Test func convierteSaltosHTMLEnLineas() {
        let entrada = "Línea<br>otra</p><p>fin"
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Línea\notra\nfin")
    }

    @Test func quitaSeparadoresHorizontales() {
        let entrada = "Texto\n----------\nContenido"
        #expect(TextSanitizer.cleanParagraphs(entrada) == "Texto\n\nContenido")
    }

    @Test func noConfundeOperacionesConEnfasis() {
        #expect(TextSanitizer.cleanParagraphs("5 * 3 = 15") == "5 * 3 = 15")
    }

    @Test func descripcionVaciaQuedaVacia() {
        #expect(TextSanitizer.cleanParagraphs(" \r\n \u{00A0} ").isEmpty)
    }
}
