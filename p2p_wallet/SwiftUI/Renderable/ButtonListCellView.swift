import SwiftUI
import KeyAppUI

struct ButtonListCellItem: Identifiable {
    var id = UUID().uuidString
    let leadingImage: UIImage?
    let title: String
    let action: () -> Void
    let style: TextButton.Style
    let trailingImage: UIImage?
}

extension ButtonListCellItem: Renderable {
    func render() -> some View {
        ButtonListCellView(
            leadingImage: leadingImage,
            title: title,
            action: action,
            style: style,
            trailingImage: trailingImage
        )
    }
}

struct ButtonListCellView: View {
    let leadingImage: UIImage?
    let title: String
    let action: () -> Void
    let style: TextButton.Style
    let trailingImage: UIImage?

    var body: some View {
        NewTextButton(
            title: title,
            style: style,
            leading: leadingImage,
            trailing: trailingImage,
            action: action
        )
    }
}

struct ButtonListCellView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonListCellView(
            leadingImage: nil,
            title: "Text",
            action: {},
            style: .inverted,
            trailingImage: nil
        )
    }
}
