import SwiftUI
import KeyAppUI

struct ListBackgroundModifier: ViewModifier {
    let separatorColor: UIColor

    @ViewBuilder
    func body(content: Content) -> some View {
        // Hide default system background color for different iOS versions
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
                .listRowSeparatorTint(Color(separatorColor))
        } else {
            content
                .introspectTableView(customize: { view in
                    view.backgroundColor = .clear
                    view.separatorColor = separatorColor
                })
        }
    }
}
