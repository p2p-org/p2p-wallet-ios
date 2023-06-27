import KeyAppUI
import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    @FocusState var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(uiImage: Asset.MaterialIcon.magnifyingGlass.image)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.gray)
                .frame(width: 15, height: 15)

            TextField(L10n.search, text: $searchText)
                .foregroundColor(Color(Asset.Colors.night.color))
                .focused($isFocused)
                .frame(height: 38)
                .submitLabel(.done)
                .onSubmit {
                    isFocused = false
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
    }
}
