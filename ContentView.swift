import SwiftUI
import SwiftData

struct Book: Identifiable {
let id = UUID()
let title: String
let author: String
let year: String
let genre: String
let description: String
}

let sampleBooks: [Book] = [
Book(title: "La Odisea", author: "Homero", year: "Desconocido", genre: "Aventura",
description: "Tras la guerra de Troya, Odiseo emprende un largo viaje de regreso a su hogar en Ítaca."),
Book(title: "El principito", author: "Antoine de Saint-Exupéry", year: "1943", genre: "Fantasía",
description: "Un piloto perdido en el desierto conoce a un pequeño príncipe que viene de otro planeta."),
Book(title: "Cien años de soledad", author: "Gabriel García Márquez", year: "1967", genre: "Realismo mágico",
description: "La historia de varias generaciones de la familia Buendía en el pueblo de Macondo."),
Book(title: "Pedro Páramo", author: "Juan Rulfo", year: "1955", genre: "Realismo mágico",
description: "Juan Preciado llega a Comala buscando a su padre y encuentra un pueblo lleno de murmullos."),
Book(title: "Don Quijote de la Mancha", author: "Miguel de Cervantes", year: "1605", genre: "Clásico",
description: "Un hidalgo sale a buscar aventuras como caballero andante junto a Sancho Panza."),
Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror",
description: "Un científico da vida a una criatura y tiene que enfrentar las consecuencias.")
]

struct ContentView: View {
@State private var searchText: String = ""

var filteredBooks: [Book] {
if searchText.isEmpty {
return sampleBooks
}
return sampleBooks.filter { book in
book.title.localizedCaseInsensitiveContains(searchText) ||
book.author.localizedCaseInsensitiveContains(searchText)
}
}

var body: some View {
NavigationStack {
VStack(alignment: .leading, spacing: 16) {
HeaderView()

SearchBar(text: $searchText)

if filteredBooks.isEmpty {
EmptyStateView(searchText: searchText)
} else {
ScrollView {
VStack(spacing: 12) {
ForEach(filteredBooks) { book in
NavigationLink {
SecondView(book: book)
} label: {
BookRow(book: book)
}
.buttonStyle(.plain)
}
}
}
}
}
.padding(.horizontal)
.background(Color.black)
}
.preferredColorScheme(.dark)
}
}

struct HeaderView: View {
var body: some View {
VStack(alignment: .leading, spacing: 4) {
Text("AJBooks")
.font(.largeTitle)
.italic()
.bold()
.foregroundStyle(.red)
.accessibilityAddTraits(.isHeader)

Text("Libros en tendencia")
.font(.headline)
.foregroundStyle(.gray)
}
.padding(.top)
}
}

struct SearchBar: View {
@Binding var text: String

var body: some View {
HStack {
Image(systemName: "magnifyingglass")
.foregroundStyle(.gray)
.accessibilityHidden(true)

TextField("Título o autor", text: $text)
.foregroundStyle(.white)

if !text.isEmpty {
Button {
text = ""
} label: {
Image(systemName: "xmark.circle.fill")
.foregroundStyle(.gray)
.frame(width: 44, height: 44)
}
.accessibilityLabel("Limpiar búsqueda")
}
}
.padding(.leading)
.frame(minHeight: 44)
.background(Color(white: 0.15))
.clipShape(RoundedRectangle(cornerRadius: 10))
}
}

struct BookCover: View {
var body: some View {
ZStack {
RoundedRectangle(cornerRadius: 6)
.fill(Color(white: 0.25))
Image(systemName: "book.closed")
.font(.title2)
.foregroundStyle(.gray)
}
.frame(width: 60, height: 90)
.accessibilityHidden(true)
}
}

struct BookRow: View {
let book: Book

var body: some View {
HStack(spacing: 12) {
BookCover()

VStack(alignment: .leading, spacing: 4) {
Text(book.title)
.font(.headline)
.foregroundStyle(.white)
Text(book.author)
.font(.subheadline)
.foregroundStyle(.gray)
Text("\(book.year) · \(book.genre)")
.font(.caption)
.foregroundStyle(.red)
}

Spacer()

Image(systemName: "chevron.right")
.foregroundStyle(.gray)
.accessibilityHidden(true)
}
.padding()
.background(Color(white: 0.12))
.clipShape(RoundedRectangle(cornerRadius: 12))
.accessibilityElement(children: .combine)
}
}

struct EmptyStateView: View {
let searchText: String

var body: some View {
VStack(spacing: 12) {
Spacer()
Image(systemName: "books.vertical")
.font(.largeTitle)
.foregroundStyle(.gray)
.accessibilityHidden(true)
Text("Sin resultados")
.font(.title3)
.bold()
.foregroundStyle(.white)
Text("No encontramos libros para \"\(searchText)\".")
.font(.subheadline)
.foregroundStyle(.gray)
.multilineTextAlignment(.center)
Spacer()
}
.frame(maxWidth: .infinity)
}
}
#Preview {
ContentView()
}

