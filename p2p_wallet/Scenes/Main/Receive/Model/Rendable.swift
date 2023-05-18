import KeyAppUI
import SwiftUI

/// In case of successful experiment make a base Renderable protocol
protocol Rendable<ViewType>: Identifiable where ID == String {
    associatedtype ViewType: View

    var id: String { get }

    @ViewBuilder func render() -> ViewType
}

/// Opaque type for cell views
struct AnyRendable: View, Identifiable {
    var item: any Rendable

    var id: String { item.id }

    init(item: any Rendable) {
        self.item = item
    }

    var body: some View {
        AnyView(item.render())
    }
}
