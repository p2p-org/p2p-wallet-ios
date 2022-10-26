import KeyAppUI
import SwiftUI

struct PageContent<Content>: Identifiable where Content: View {
    let uuid = UUID().uuidString
    let view: () -> Content
    var id: String { uuid }
}

struct PagingView<Content>: View where Content: View {
    @State private var currentIndex: Int = 0

    private let fillColor: Color
    private let content: [PageContent<Content>]

    init(
        fillColor: Color,
        content: [PageContent<Content>]
    ) {
        self.fillColor = fillColor
        self.content = content
    }

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentIndex.animation()) {
                ForEach(Array(content.enumerated()), id: \.element.id) { index, element in
                    element
                        .view()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageControl(index: $currentIndex, maxIndex: content.count - 1, fillColor: fillColor)
        }
    }
}
