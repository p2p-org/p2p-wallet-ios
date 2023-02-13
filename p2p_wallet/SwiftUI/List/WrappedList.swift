import SwiftUI
import KeyAppUI

struct WrappedList<Content: View>: View {
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 15, *) {
            List {
                content()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .background(Color(Asset.Colors.smoke.color))
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    content()
                }
                .background(Color(Asset.Colors.smoke.color))
            }
        }
    }
}
