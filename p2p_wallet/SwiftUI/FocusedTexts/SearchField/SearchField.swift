import KeyAppUI
import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    @Binding var isSearchFieldFocused: Bool
    let clearSearchAction: () -> Void

    var body: some View {
        HStack(spacing: .zero) {
            Image(uiImage: .standardSearch)
                .searchFieldStyle()

            FocusedTextField(
                text: $searchText,
                isFirstResponder: $isSearchFieldFocused
            ) { textField in
                textField.returnKeyType = .done
                textField.autocorrectionType = .no
                textField.spellCheckingType = .no
                textField.placeholder = L10n.search
                textField.font = .font(of: .text1)
                textField.textColor = .gray
            }

            if !searchText.isEmpty {
                Button(action: clearSearchAction) {
                    Image(uiImage: .clean)
                        .searchFieldStyle()
                }
                .frame(height: 38)
            }
        }
        .background(Color(.gray.withAlphaComponent(0.12)))
        .cornerRadius(10)
        .frame(height: 38)
    }
}

private extension Image {
    func searchFieldStyle() -> some View {
        return self
            .renderingMode(.template)
            .foregroundColor(Color(.gray))
            .frame(width: 16, height: 16)
            .padding(.horizontal, 8)
    }
}
