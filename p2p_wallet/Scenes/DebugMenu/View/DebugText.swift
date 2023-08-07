import SwiftUI
import UniformTypeIdentifiers

struct DebugText: View {
    let title: String?
    let value: String

    var body: some View {
        Button {
            UIPasteboard.general.setValue(value, forPasteboardType: UTType.plainText.identifier)
        } label: {
            HStack {
                if let title {
                    Text(title)
                    Spacer()
                }
                Text(value)
            }
        }
    }
}

struct DebugText_Previews: PreviewProvider {
    static var previews: some View {
        DebugText(title: "Some property", value: "Value")
    }
}
