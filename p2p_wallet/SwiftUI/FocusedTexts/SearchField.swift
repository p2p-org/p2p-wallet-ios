import KeyAppUI
import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    @Binding var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: .zero) {
            FocusedTextField<UISearchTextField>(
                text: $searchText,
                isFirstResponder: $isSearchFieldFocused
            ) { searchField in
                searchField.returnKeyType = .done
                searchField.autocorrectionType = .no
                searchField.spellCheckingType = .no
                searchField.placeholder = L10n.search
                searchField.textColor = Asset.Colors.night.color
            }
        }
        .cornerRadius(10)
        .frame(height: 38)
    }
}
