import Combine
import KeyAppUI
import SwiftUI

struct SeedPhraseRestoreWalletView: View {
    @State private var seedText = ""

    var body: some View {
        VStack {
            Label("Enter your seed phrase")
        }
    }

    var inputView: some View {
        VStack {
            HStack {
                Label("Seed phrase")
                Spacer()
                TextButtonView(title: "Paste", style: .third, size: .small)

//                TextButton(
//                    title: <#T##String#>,
//                    style: .third,
//                    size: .small,
//                    leading: Asset.MaterialIcon.<#name#>.image
//                )
//                .onPressed { <#code#> }
            }
            TextEditor(text: $seedText)
        }
    }

    var pasteButton: some View {
        TextButtonView(title: "Paste", style: .third, size: .small, leading: Asset.MaterialIcon.paste.image)
    }
}
