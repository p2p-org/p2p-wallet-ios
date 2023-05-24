import SwiftUI
import KeyAppUI

struct ButtonListCellItem: Identifiable {
    var id = UUID().uuidString
    let leadingImage: UIImage?
    let title: String
    let trailingImage: UIImage?
}

struct ButtonListCellView: View {
    let leadingImage: UIImage?
    let title: String
    let trailingImage: UIImage?
    
    var body: some View {
        VStack {}
    }
}

struct ButtonListCellView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonListCellView(leadingImage: nil, title: "", trailingImage: nil)
    }
}
