import Combine
import SwiftUI

struct SheetHeaderModifier: ViewModifier {
    let title: String?
    var withSeparator: Bool = true
    var bottomPadding: CGFloat = 20
    let close: (() -> Void)?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: title, withSeparator: withSeparator, bottomPadding: bottomPadding, close: close)
            Spacer()
            content
        }.background(Color(.snow))
            .cornerRadius(radius: 18, corners: [.topLeft, .topRight])
    }
}

extension View {
    func sheetHeader(
        title: String?,
        withSeparator: Bool = true,
        bottomPadding: CGFloat = 20,
        close: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetHeaderModifier(
            title: title,
            withSeparator: withSeparator,
            bottomPadding: bottomPadding,
            close: close
        ))
    }
}

private struct SheetHeaderView: View {
    let title: String?
    let withSeparator: Bool
    let bottomPadding: CGFloat
    let close: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Color(.rain)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)
            HStack(alignment: .bottom, spacing: 0) {
                if close != nil {
                    Spacer()
                }
                if let title {
                    Text(title)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .title3, weight: .semibold))
                        .padding(.top, 18)
                }
                if let close = close {
                    Spacer()
                    Button(
                        action: {
                            close()
                        },
                        label: {
                            Image(.closeAction)
                        }
                    )
                }
            }
            .padding(.trailing, 16)
            .padding(.leading, close != nil ? 32 : 16)
            .padding(.bottom, bottomPadding)
            if withSeparator {
                Color(.rain)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
