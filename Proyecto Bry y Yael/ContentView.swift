import SwiftUI

struct Book: Identifiable {
    var id = UUID()
    var title: String
    
    
    
    var author: String
    var year: String
    var genre: String
    var description: String
}

let books = [
    Book(title: "La Odisea", author: "Homero", year: "Desconocido", genre: "Aventura", description: "Tras la guerra de Troya, Odiseo emprende un largo viaje de regreso a su hogar en Ítaca."),
    Book(title: "El principito", author: "Antoine de Saint-Exupéry", year: "1943", genre: "Fantasía", description: "Un piloto perdido en el desierto conoce a un pequeño príncipe que viene de otro planeta."),
    Book(title: "Cien años de soledad", author: "Gabriel García Márquez", year: "1967", genre: "Realismo mágico", description: "La historia de varias generaciones de la familia Buendía en el pueblo de Macondo."),
    Book(title: "Pedro Páramo", author: "Juan Rulfo", year: "1955", genre: "Realismo mágico", description: "Juan Preciado llega a Comala buscando a su padre y encuentra un pueblo lleno de murmullos."),
    Book(title: "Don Quijote de la Mancha", author: "Miguel de Cervantes", year: "1605", genre: "Clásico", description: "Un hidalgo sale a buscar aventuras como caballero andante junto a Sancho Panza."),
    Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "Un científico da vida a una criatura y tiene que enfrentar las consecuencias.")
]

struct ContentView: View {
    @State var searchText = ""

    var body: some View {
    NavigationView {
    VStack(alignment: .leading, spacing: 12) {
    Text("AJBooks")
    .font(.largeTitle)
    .bold()
    .foregroundColor(.red)

    Text("Libros en tendencia")
    .foregroundColor(.gray)

    TextField("Buscar libro", text: $searchText)
    .padding(10)
    .background(Color.gray.opacity(0.2))
    .cornerRadius(8)

    ScrollView {
    VStack(spacing: 10) {
    ForEach(books) { book in
    if searchText == "" || book.title.lowercased().contains(searchText.lowercased()) {
    NavigationLink(destination: SecondView(book: book)) {
    HStack {
    Image(systemName: "book.closed")
    .font(.largeTitle)
    .frame(width: 60, height: 80)
    .background(Color.gray.opacity(0.3))
    .cornerRadius(6)

    VStack(alignment: .leading, spacing: 5) {
    Text(book.title)
    .font(.headline)
    .foregroundColor(.white)

     Text(book.author)
    .foregroundColor(.gray)

     Text(book.year + " - " + book.genre)
     .font(.caption)
    .foregroundColor(.red)
     }

    Spacer()
    }
    .padding(10)
    .background(Color.gray.opacity(0.15))
    .cornerRadius(10)
    }
        }
            }
                }
                    }
                        }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
