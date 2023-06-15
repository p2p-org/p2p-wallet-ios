import SwiftUI

struct WrapperForSearchingView<Content: View>: View {
    
    @SwiftUI.Environment(\.isSearching) private var isSearching
    
    @Binding var searching: Bool
    @ViewBuilder var content: Content
    
    var body: some View {
        content
            .onChange(of: isSearching) { value in
                searching = value
            }
    }
}
