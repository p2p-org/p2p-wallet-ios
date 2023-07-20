import SwiftUI

public struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = 0
    public let indicatorColor: Color

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public init(indicatorColor: Color) {
        self.indicatorColor = indicatorColor
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(indicatorColor)

                Rectangle().frame(width: geometry.size.width / 2.5, height: geometry.size.height)
                    .foregroundColor(indicatorColor)
                    .cornerRadius(geometry.size.width / 2)
                    .offset(CGSize(width: offset, height: 0))
            }
            .cornerRadius(geometry.size.width / 2)
            .onReceive(timer) { _ in
                let progressWidth = geometry.size.width / 2.5
                withAnimation(.easeIn) {
                    offset += 15
                }
                if offset >= geometry.size.width + progressWidth {
                    offset = -progressWidth
                }
            }
        }
        .frame(height: 4)
    }
}

struct IndeterminateProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        IndeterminateProgressBar(indicatorColor: Color(Asset.Colors.night.color))
    }
}
