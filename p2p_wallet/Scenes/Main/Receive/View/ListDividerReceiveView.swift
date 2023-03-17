import KeyAppUI
import SwiftUI

struct ListDividerReceiveView: View {
    var body: some View {
        ZStack {
            Color(Asset.Colors.snow.color)
            Divider()
                .frame(height: 1)
                .background(Color(Asset.Colors.rain.color))
                .padding(.leading, 20)
        }
        .frame(height: 1)
    }
}

struct ListDividerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListDividerReceiveView()
    }
}
