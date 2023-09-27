import SwiftUI

enum ChooseItemSearchableItemViewState {
    case first, last, single, other
}

struct ChooseItemSearchableItemView<Content: View>: View {
    private let state: ChooseItemSearchableItemViewState
    @ViewBuilder private let content: (ChooseItemSearchableItemViewModel) -> Content
    private let model: ChooseItemSearchableItemViewModel

    init(
        @ViewBuilder content: @escaping (ChooseItemSearchableItemViewModel) -> Content,
        state: ChooseItemSearchableItemViewState,
        item: any ChooseItemSearchableItem,
        isChosen: Bool
    ) {
        self.content = content
        self.state = state
        model = ChooseItemSearchableItemViewModel(item: item, isChosen: isChosen)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content(model)
                .padding(.horizontal, 16)
                .frame(height: 72)
            if state == .first || state == .other {
                Rectangle()
                    .foregroundColor(Color(.rain))
                    .frame(height: 1)
                    .padding(.leading, 20)
            }
        }
        .background(
            Rectangle()
                .cornerRadius(radius: state == .other ? 0 : 16, corners: cornerRadius())
                .foregroundColor(Color(.snow))
        )
        .padding(.horizontal, 16)
        .listRowBackground(Color(.smoke))
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
