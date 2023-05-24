import KeyAppUI
import SwiftUI
import CountriesAPI

extension Country: ChooseItemRenderable {
    typealias ViewType = AnyView

    func render() -> AnyView {
        AnyView(
            countryView(
                flag: emoji ?? "",
                title: name
            )
        )
    }

    private func countryView(flag: String, title: String) -> some View {
        HStack(spacing: 10) {
            Text(flag)
                .font(uiFont: .font(of: .title1, weight: .bold))
            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text3))
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
