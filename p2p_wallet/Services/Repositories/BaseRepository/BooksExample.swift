//
//  BooksExample.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/02/2023.
//

import Foundation

// Start with a model
struct Book: Hashable & Identifiable {
    var id = UUID()
    let name: String
}

// Then a Repository
final class BooksRepository: ListRepository<Book> {
    override func fetch() async throws -> [Book] {
        [
            .init(name: "Book1"),
            .init(name: "Book2")
        ]
    }
}

// Then form viewModel
@MainActor class Test {
    func test() {
        let vm = ListViewModel(
            initialData: nil,
            repository: BooksRepository(paginationStrategy: nil)
        )
    }
}
