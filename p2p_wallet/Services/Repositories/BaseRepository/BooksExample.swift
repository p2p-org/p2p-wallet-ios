//
//  BooksExample.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/02/2023.
//

import Foundation
import SwiftUI

// Start with a model
struct Book: Hashable & Identifiable {
    var id = UUID()
    let name: String
}

// Then a Repository
final class BooksRepository: AnyListRepository {
    func shouldFetch() -> Bool {
        true
    }
    
    func fetch() async throws -> [Book] {
        []
    }
}

//// Then form viewModel
@MainActor class Test {
    func test() {
        let vm = ListViewModel(
            repository: BooksRepository()
        )
    }
}
