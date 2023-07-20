import SwiftUI
import KeyAppUI

struct ActionsCellView: View {
    let icon: UIImage
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(uiFont: .font(of: .text3, weight: .semibold))
                            .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(subtitle)
                            .font(uiFont: .font(of: .label1, weight: .regular))
                            .foregroundColor(Color(red: 0.44, green: 0.49, blue: 0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 12)
                }
                .padding()
                Image(uiImage: UIImage.chevronRight)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 12)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
        }
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(16)
    }
}

struct ActionsCellViewPreview: PreviewProvider {
    static var previews: some View {
        ActionsCellView(icon: .appleIcon, title: "Test", subtitle: "Test", action: {  })
    }
}
