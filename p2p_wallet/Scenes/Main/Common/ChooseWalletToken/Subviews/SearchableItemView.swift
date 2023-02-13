import SwiftUI
import KeyAppUI

enum SearchableItemViewState {
    case first, last, single, other
}

struct SearchableItemView<Content: View>: View {

    private let state: SearchableItemViewState
    private let item: any SearchableItem
    @ViewBuilder private let content: (any SearchableItem) -> Content

    init(
        @ViewBuilder content: @escaping (any SearchableItem) -> Content,
        state: SearchableItemViewState,
        item: any SearchableItem
    ) {
        self.content = content
        self.state = state
        self.item = item
    }

    var body: some View {
        content(item)
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(
                Rectangle()
                    .cornerRadius(radius: state == .other ? 0 : 16, corners: cornerRadius())
                    .foregroundColor(Color(Asset.Colors.snow.color))
            )
            .padding(.horizontal, 16)
    }

    func cornerRadius() -> UIRectCorner {
        switch state {
        case .first:
            return [.topLeft, .topRight]
        case .last:
            return [.bottomLeft, .bottomRight]
        case .single, .other:
            return .allCorners
        }
    }
}
