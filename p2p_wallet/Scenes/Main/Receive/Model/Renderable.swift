import KeyAppUI
import SwiftUI

/// In case of successful experiment make a base Renderable protocol
protocol Renderable<ViewType>: Identifiable where ID == String {
    associatedtype ViewType: View

    var id: String { get }

    @ViewBuilder func render() -> ViewType
}

/// Opaque type for cell views
struct AnyRenderable: View, Identifiable {
    var item: any Renderable

    var id: String { item.id }

    init(item: any Renderable) {
        self.item = item
    }

    var body: some View {
        AnyView(item.render())
    }
}
