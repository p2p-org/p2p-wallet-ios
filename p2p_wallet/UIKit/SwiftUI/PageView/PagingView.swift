import KeyAppUI
import SwiftUI

struct PagingView<Content>: View where Content: View {
    @Binding var index: Int

    let maxIndex: Int
    let fillColor: Color
    let content: () -> Content

    @State private var offset = CGFloat.zero
    @State private var dragging = false

    init(
        index: Binding<Int>,
        maxIndex: Int,
        fillColor: Color,
        @ViewBuilder content: @escaping () -> Content
    ) {
        _index = index
        self.fillColor = fillColor
        self.maxIndex = maxIndex
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                Spacer()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .zero) {
                        self.content()
                            .frame(width: geometry.size.width)
                    }
                }
                .content.offset(x: self.offset(in: geometry), y: 0)
                .frame(width: geometry.size.width, alignment: .leading)
                .gesture(
                    DragGesture().onChanged { value in
                        self.dragging = true
                        self.offset = -CGFloat(self.index) * geometry.size.width + value.translation.width
                    }
                    .onEnded { value in
                        let predictedEndOffset = -CGFloat(self.index) * geometry.size.width + value
                            .predictedEndTranslation.width
                        let predictedIndex = Int(round(predictedEndOffset / -geometry.size.width))
                        self.index = self.clampedIndex(from: predictedIndex)
                        withAnimation(.easeOut) {
                            self.dragging = false
                        }
                    }
                )

                PageControl(index: $index, maxIndex: maxIndex, fillColor: fillColor)

                Spacer()
            }
        }
    }

    func offset(in geometry: GeometryProxy) -> CGFloat {
        if dragging {
            return max(min(offset, 0), -CGFloat(maxIndex) * geometry.size.width)
        } else {
            return -CGFloat(index) * geometry.size.width
        }
    }

    func clampedIndex(from predictedIndex: Int) -> Int {
        let newIndex = min(max(predictedIndex, index - 1), index + 1)
        guard newIndex >= 0 else { return 0 }
        guard newIndex <= maxIndex else { return maxIndex }
        return newIndex
    }
}
