import SwiftUI
import KeyAppUI

enum StrigaRegistrationTextFieldStatus: Equatable {
    case valid
    case invalid(error: String)
}

struct StrigaRegistrationCell<Content: View>: View {
    let title: String
    let status: StrigaRegistrationTextFieldStatus
    @ViewBuilder private var content: () -> Content

    init(
        title: String,
        status: StrigaRegistrationTextFieldStatus? = .valid,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.status = status ?? .valid
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(Color(asset: Asset.Colors.mountain))
                .apply(style: .label1)
                .padding(.leading, 8)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(asset: Asset.Colors.snow))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(status == .valid ? .clear : Color(asset: Asset.Colors.rose), lineWidth: 1)
                )

            if case .invalid(let error) = status {
                Text(error)
                    .apply(style: .label1)
                    .foregroundColor(Color(asset: Asset.Colors.rose))
                    .padding(.leading, 8)
            }
        }
    }
}
