import KeyAppUI
import SwiftUI

struct HomeActionsView: View {
    let actions: [HomeAction]
    let action: (HomeAction) -> Void

    var body: some View {
        HStack {
            Spacer()
            ForEach(actions, id: \.text) { actionType in
                actionView(title: actionType.text, image: actionType.image) {
                    action(actionType)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
    }

    private func actionView(
        title: String,
        image: UIImage,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action,
            label: {
                HStack(spacing: 0) {
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .padding(
                            EdgeInsets(
                                top: 14,
                                leading: 10,
                                bottom: 14,
                                trailing: 5
                            )
                        )
                    Image(uiImage: image)
                }
                .frame(maxWidth: .infinity)
            }
        )
        .background(Color(Asset.Colors.night.color))
        .cornerRadius(radius: 12, corners: .allCorners)
    }
}

struct HomeActionsPreview: PreviewProvider {
    static var previews: some View {
        HomeActionsView(actions: [.addMoney, .withdraw], action: { _ in })
    }
}
