import KeyAppUI
import SwiftUI

struct ListSpacerCellViewItem: Identifiable {
    var id = UUID().uuidString
    let height: CGFloat
    let backgroundColor: Color
    var leadingPadding: CGFloat = .zero
}

extension ListSpacerCellViewItem: Renderable {
    func render() -> some View {
        ListSpacerCellView(height: height, backgroundColor: backgroundColor, leadingPadding: leadingPadding)
    }
}

struct ListSpacerCellView: View {
    let height: CGFloat
    let backgroundColor: Color
    var leadingPadding: CGFloat = .zero

    var body: some View {
        backgroundColor
            .frame(height: height)
            .padding(.leading, leadingPadding)
    }
}

struct ListSpacerCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListSpacerCellView(height: 10, backgroundColor: .blue, leadingPadding: 20)
    }
}
