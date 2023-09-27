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
                Image(.chevronRight)
            }.padding(.horizontal, 16)
        }
        .frame(height: 55)
        .foregroundColor(Color(.night))
        .background(Color(.snow))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.rain), lineWidth: 1)
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
