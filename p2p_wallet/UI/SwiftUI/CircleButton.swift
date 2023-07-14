import SwiftUI

struct CircleButton: View {
    let title: String
    let image: ImageResource
    let onPressed: () -> Void

    var body: some View {
        Button {
            onPressed()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(.night))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(image)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                    )
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .label2)
                    .foregroundColor(Color(.night))
            }
        }
    }
}

struct NewHistoryButtonAction_Previews: PreviewProvider {
    static var previews: some View {
        CircleButton(title: "Share", image: .share2) {}
    }
}
