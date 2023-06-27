import SwiftUI
import KeyAppUI

struct ButtonListCellItem: Identifiable {
    var id = UUID().uuidString
    let leadingImage: UIImage?
    let title: String
    let action: () -> Void
    let style: TextButton.Style
    let trailingImage: UIImage?
    let horizontalPadding = CGFloat(4)
}

extension ButtonListCellItem: Renderable {
    func render() -> some View {
        NewTextButton(
            title: title,
            style: style,
            expandable: true,
            leading: leadingImage,
            trailing: trailingImage,
            action: action
        )
        .padding(.horizontal, horizontalPadding)
    }
}
