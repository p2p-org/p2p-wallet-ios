import KeyAppUI
import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    @Binding var isFocused: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            NewSearchField(
                searchText: $searchText,
                isFocused: $isFocused
            )
        } else {
            FocusedTextField<UISearchTextField>(
                text: $searchText,
                isFirstResponder: $isFocused
            ) { searchField in
                searchField.returnKeyType = .done
                searchField.autocorrectionType = .no
                searchField.spellCheckingType = .no
                searchField.placeholder = L10n.search
                searchField.textColor = Asset.Colors.night.color
            }
            .cornerRadius(10)
            .frame(height: 38)
        }
    }
}

@available(iOS 15.0, *)
private struct NewSearchField: View {
    @Binding var searchText: String
    @Binding var isFocused: Bool

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(uiImage: Asset.MaterialIcon.magnifyingGlass.image)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.gray)
                .frame(width: 15, height: 15)

            TextField(L10n.search, text: $searchText)
                .foregroundColor(Color(Asset.Colors.night.color))
                .focused($isSearchFieldFocused)
                .frame(height: 38)
                .submitLabel(.done)
                .onSubmit {
                    isSearchFieldFocused = false
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(uiImage: .crossIcon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.gray)
                        .frame(width: 14, height: 14)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(Color(UIColor._767680))
        .cornerRadius(10)
        .onChange(of: isFocused) { newValue in
            self.isSearchFieldFocused = isFocused
        }
    }
}
