import Foundation
import SwiftUI

/// View of `CryptoPending` scene
struct CryptoPendingView: View {
    
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoPendingViewModel
    
    // MARK: - Initializer
    
    init(viewModel: CryptoPendingViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View content

    var body: some View {
        Text("CryptoPending")
    }
}
