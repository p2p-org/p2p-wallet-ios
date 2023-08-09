import Foundation
import KeyAppUI
import SwiftUI

struct SettingsRowView<Leading: View>: View {
    let title: String
    let withArrow: Bool
    @ViewBuilder let leading: Leading

    var body: some View {
        HStack(spacing: 12) {
            leading
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2))
                .lineLimit(1)
            if withArrow {
                Spacer()
                Image(uiImage: .cellArrow)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }
}

struct SettingsRow_Preview: PreviewProvider {
    static var previews: some View {
        SettingsRowView(title: "Example", withArrow: true) {
            Image(uiImage: UIImage.recoveryKit)
                .overlay(
                    AlertIndicatorView(fillColor: Color(Asset.Colors.rose.color)).offset(x: 2.5, y: -2.5),
                    alignment: .topTrailing
                )
        }
    }
}
