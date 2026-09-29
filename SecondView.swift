import SwiftUI
import SwiftData

struct SecondView: View {
let book: Book
@State private var isSaved: Bool = false

var body: some View {
ScrollView {
VStack(alignment: .leading, spacing: 20) {

HStack(alignment: .top, spacing: 16) {
ZStack {
RoundedRectangle(cornerRadius: 10)
.fill(Color(white: 0.25))
Image(systemName: "book.closed")
.font(.largeTitle)
.foregroundStyle(.gray)
}
.frame(width: 120, height: 180)
.accessibilityHidden(true)

VStack(alignment: .leading, spacing: 8) {
Text(book.title)
.font(.title2)
.bold()
.foregroundStyle(.white)
.accessibilityAddTraits(.isHeader)
Text(book.author)
.font(.subheadline)
.foregroundStyle(.gray)
}
}

Button {
isSaved.toggle()
} label: {
HStack {
Image(systemName: isSaved ? "heart.fill" : "heart")
Text(isSaved ? "Guardado" : "Guardar")
}
.font(.headline)
.foregroundStyle(.white)
.frame(maxWidth: .infinity, minHeight: 44)
.background(isSaved ? Color.red : Color(white: 0.2))
.clipShape(RoundedRectangle(cornerRadius: 10))
}
.accessibilityLabel(isSaved ? "Quitar de guardados" : "Guardar libro")

VStack(alignment: .leading, spacing: 8) {
Text("Descripción")
.font(.headline)
.foregroundStyle(.white)
.accessibilityAddTraits(.isHeader)
Text(book.description)
.font(.body)
.foregroundStyle(.gray)
}

VStack(spacing: 0) {
DetailRow(label: "Autor", value: book.author)
Divider()
DetailRow(label: "Año", value: book.year)
Divider()
DetailRow(label: "Género", value: book.genre)
}
.padding(.horizontal)
.background(Color(white: 0.12))
.clipShape(RoundedRectangle(cornerRadius: 12))
}
.padding()
}
.background(Color.black)
.navigationTitle("Detalle")
.navigationBarTitleDisplayMode(.inline)
}
}

struct DetailRow: View {
let label: String
let value: String

var body: some View {
HStack {
Text(label)
.foregroundStyle(.gray)
Spacer()
Text(value)
.foregroundStyle(.white)
.multilineTextAlignment(.trailing)
}
.font(.subheadline)
.padding(.vertical, 12)
.accessibilityElement(children: .combine)
}
}

#Preview {
NavigationStack {
SecondView(book: sampleBooks[0])
}
.preferredColorScheme(.dark)
}
