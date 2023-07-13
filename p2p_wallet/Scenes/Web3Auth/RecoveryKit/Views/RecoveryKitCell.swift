import KeyAppUI
import SwiftUI

struct RecoveryKitCell: View {
    let icon: ImageResource
    let title: String
    let onTap: (() -> Void)?

    var body: some View {
        Button { onTap?() } label: {
            HStack {
                Image(icon)
                    .padding(.trailing, 12)
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                Spacer()
                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
            }.padding(.horizontal, 16)
        }
        .frame(height: 55)
        .foregroundColor(Color(Asset.Colors.night.color))
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
        )
    }
}

struct RecoveryKitCell_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.gray)
            RecoveryKitCell(icon: .keyIcon, title: "Seed phrase") {}
        }
    }
}
