import SwiftUI

struct DebugTextField: View {
    let title: String
    let content: Binding<String>

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
            Spacer()
            TextField("Value", text: content)
        }
    }
}

struct DebugTextField_Previews: PreviewProvider {
    static var previews: some View {
        DebugTextField(title: "Property", content: .constant("Value"))
    }
}
