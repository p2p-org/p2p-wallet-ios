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
                textField.backgroundColor = Asset.Colors.rain.color
                textField.placeholder = L10n.search
                textField.font = .font(of: .text3)
            }

            if !searchText.isEmpty {
                Button(action: clearSearchAction) {
                    Image(uiImage: .clean)
                        .searchFieldStyle()
                }
                .frame(height: 44)
            }
        }
        .background(Color(Asset.Colors.rain.color))
        .cornerRadius(12)
        .frame(height: 44)
    }
}

private extension Image {
    func searchFieldStyle() -> some View {
        return self
            .renderingMode(.template)
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .frame(width: 20, height: 20)
            .padding(.horizontal, 10)
    }
}
