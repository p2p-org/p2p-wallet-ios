import KeyAppUI
import SwiftUI

public struct HandleBarView: View {
    public var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(UIColor(red: 0.82, green: 0.82, blue: 0.839, alpha: 1)))
            .frame(width: 30, height: 4)
    }
}

struct HandleBarView_Previews: PreviewProvider {
    static var previews: some View {
        HandleBarView()
    }
}
