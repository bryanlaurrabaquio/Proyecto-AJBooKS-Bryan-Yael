import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case content([Book])
    case empty
    case error(BookServiceError)
}
