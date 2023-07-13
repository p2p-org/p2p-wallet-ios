import KeyAppUI
import SwiftUI

struct ListDividerReceiveView: View {
    var body: some View {
        ZStack {
            Color(.snow)
            Divider()
                .frame(height: 1)
                .background(Color(.rain))
        }
        .frame(height: 1)
    }
}

struct ListDividerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListDividerReceiveView()
    }
}
