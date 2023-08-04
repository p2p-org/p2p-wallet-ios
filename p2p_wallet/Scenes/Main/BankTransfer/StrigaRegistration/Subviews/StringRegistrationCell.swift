import SwiftUI
import KeyAppUI

enum StrigaFormTextFieldStatus: Equatable {
    case valid
    case invalid(error: String)
}

struct StrigaFormCell<Content: View>: View {
    let title: String
    let status: StrigaFormTextFieldStatus
    let hint: String?
    @ViewBuilder private var content: () -> Content

    init(
        title: String,
        status: StrigaFormTextFieldStatus? = .valid,
        hint: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.status = status ?? .valid
        self.hint = hint
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(Color(asset: Asset.Colors.mountain))
                .apply(style: .label1)
                .padding(.leading, 9)
                .frame(minHeight: 16)

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
            } else if let hint {
                Text(hint)
                    .apply(style: .label1)
                    .foregroundColor(Color(asset: Asset.Colors.mountain))
                    .padding(.leading, 8)
            }
        }
    }
}
