import KeyAppUI
import SwiftUI

struct ListSpacerCellViewItem: Identifiable {
    var id = UUID().uuidString
    let height: CGFloat
    let backgroundColor: Color
}

extension ListSpacerCellViewItem: Renderable {
    func render() -> some View {
        ListSpacerCellView(height: height, backgroundColor: backgroundColor)
    }
}

struct ListSpacerCellView: View {
    let height: CGFloat
    let backgroundColor: Color

    var body: some View {
        backgroundColor.frame(height: height)
    }
}

struct ListSpacerCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListSpacerCellView(height: 10, backgroundColor: .blue)
    }
}
