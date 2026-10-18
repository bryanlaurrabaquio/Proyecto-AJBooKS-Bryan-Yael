import SwiftUI

// Subvista reutilizable: la misma fila se usa en Inicio y en Favoritos.
struct BookRow: View {
    var book: Book

    var body: some View {
        HStack {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .frame(width: 60, height: 80)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(6)
                .accessibilityLabel("Portada de " + book.title)

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

#Preview {
    BookRow(book: BookStore().books[0])
        .preferredColorScheme(.dark)
}
