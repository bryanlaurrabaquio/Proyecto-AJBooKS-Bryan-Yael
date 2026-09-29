import SwiftUI

struct SecondView: View {
    var book: Book
    @State var saved = false

    var body: some View {
    ScrollView {
    VStack(alignment: .leading, spacing: 20) {
    HStack {
    Image(systemName: "book.closed")
    .font(.system(size: 50))
    .frame(width: 120, height: 170)
    .background(Color.gray.opacity(0.3))
    .cornerRadius(10)

    VStack(alignment: .leading, spacing: 8) {
    Text(book.title)
    .font(.title2)
    .bold()

    Text(book.author)
    .foregroundColor(.gray)
    }
        }

    Button(action: {
    if saved == false {
    saved = true
    } else {
    saved = false
    }
    }) {
    HStack {
    Image(systemName: saved ? "heart.fill" : "heart")
    Text(saved ? "Guardado" : "Guardar")
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(saved ? Color.red : Color.gray)
    .foregroundColor(.white)
    .cornerRadius(8)
    }

    Text("Descripción")
    .font(.headline)

    Text(book.description)
    .foregroundColor(.gray)

    Text("Autor: " + book.author)
    Text("Año: " + book.year)
    Text("Género: " + book.genre)
        
        
        
    }
    .padding()
        }
    .navigationTitle("Detalle")
    }
}

#Preview {
    NavigationView {
        SecondView(book: books[0])
    }
    .preferredColorScheme(.dark)
}
