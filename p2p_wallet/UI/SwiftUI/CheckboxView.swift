import SwiftUI

struct CheckboxView: View {
    @Binding var isChecked: Bool
    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            if isChecked {
                Image(uiImage: .checkboxFill)
            } else {
                Image(uiImage: .checkboxEmpty)
            }
        }
    }
}
