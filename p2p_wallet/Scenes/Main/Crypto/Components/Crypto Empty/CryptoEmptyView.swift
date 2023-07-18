import Foundation
import SwiftUI

/// View of `CryptoEmpty` scene
struct CryptoEmptyView: View {
    
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoEmptyViewModel
    
    // MARK: - Initializer
    
    init(viewModel: CryptoEmptyViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View content
    
    var body: some View {
        Text("CryptoEmpty")
    }
}
