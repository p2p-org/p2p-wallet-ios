import SwiftUI

struct PageControl: View {
    @Binding var index: Int

    let maxIndex: Int
    let fillColor: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ... maxIndex, id: \.self) { index in
                Capsule()
                    .fill(index == self.index ? fillColor : fillColor.opacity(0.6))
                    .frame(width: index == self.index ? 32 : 8, height: 8)
                    .transition(.move(edge: .leading))
            }
        }
    }
}
