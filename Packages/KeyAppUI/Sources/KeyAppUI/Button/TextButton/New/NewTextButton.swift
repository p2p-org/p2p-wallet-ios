import SwiftUI

public struct NewTextButton: View {

    private let title: String
    private let action: () -> Void
    private let size: TextButton.Size
    private let style: TextButton.Style
    private let isEnabled: Bool
    private let isLoading: Bool
    private let leading: UIImage?
    private let trailing: UIImage?

    private let appearance: NewTextButtonAppearance

    public init(
        title: String,
        size: TextButton.Size = .large,
        style: TextButton.Style,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        leading: UIImage? = nil,
        trailing: UIImage? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.size = size
        self.style = style
        self.leading = leading
        self.trailing = trailing
        self.isEnabled = isEnabled
        self.isLoading = isLoading

        self.appearance = NewTextButtonAppearance(
            backgroundColor: Color(style.backgroundColor),
            foregroundColor: Color(style.foreground),
            font: style.font(size: size),
            borderRadius: size.borderRadius,
            loadingBackgroundColor: Color(style.loadingBackgroundColor),
            loadingForegroundColor: Color(style.loadingForegroundColor),
            borderColor: style.borderColor != nil ? Color(style.borderColor!) : nil,
            borderWidth: style.borderWidth(size: size)
        )
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leading {
                    if isLoading {
                        progressView
                    } else {
                        Image(uiImage: leading)
                    }
                }

                Text(title)
                    .font(appearance.font)
                    .lineLimit(1)

                if let trailing {
                    if isLoading {
                        progressView
                    } else {
                        Image(uiImage: trailing)
                    }
                }
            }
            .frame(height: size.height)
            .frame(maxWidth: .infinity)
        }
        .foregroundColor(isEnabled ? appearance.foregroundColor : Color(Asset.Colors.mountain.color))
        .background(isEnabled ? appearance.backgroundColor : Color(Asset.Colors.rain.color))
        .cornerRadius(appearance.borderRadius)
        .disabled(!isEnabled || isLoading)
        .overlay(
            RoundedRectangle(cornerRadius: appearance.borderRadius)
                .stroke(
                    appearance.borderColor ?? .clear,
                    lineWidth: appearance.borderWidth ?? 0
                )
        )
    }

    private var progressView: some View {
        NewCircularProgressIndicator(
            backgroundColor: appearance.loadingBackgroundColor,
            foregroundColor: appearance.loadingForegroundColor,
            size: CGSize(width: 20, height: 20)
        )
        .padding(2)
    }
}

// MARK: - Preview
struct NewTextButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()

            NewTextButton(
                title: "Title",
                style: .primary,
                trailing: Asset.MaterialIcon.arrowForward.image,
                action: { }
            )
            NewTextButton(
                title: "Title",
                style: .second,
                leading: Asset.MaterialIcon.arrowForward.image,
                action: { }
            )
            NewTextButton(
                title: "Title",
                style: .invertedRed,
                action: { }
            )
            NewTextButton(
                title: "Title",
                style: .outlineLime,
                isLoading: true,
                trailing: Asset.MaterialIcon.arrowForward.image,
                action: { }
            )
            NewTextButton(
                title: "Title",
                style: .primaryWhite,
                isEnabled: false,
                action: { }
            )

            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color.orange)
    }
}
