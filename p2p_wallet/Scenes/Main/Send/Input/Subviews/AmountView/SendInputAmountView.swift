import KeyAppUI
import SwiftUI

struct SendInputAmountView: View {
    @ObservedObject private var viewModel: SendInputAmountViewModel

    private let mainColor = Asset.Colors.night.color

    init(viewModel: SendInputAmountViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    SendInputAmountField(
                        text: $viewModel.amountText,
                        isFirstResponder: $viewModel.isFirstResponder,
                        textColor: $viewModel.amountTextColor
                    ) { textField in
                        textField.font = .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold)
                        textField.placeholder = "0"
                        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                    }
                    if viewModel.amountText.isEmpty {
                        TextButtonView(
                            title: L10n.max.uppercased(),
                            style: .second,
                            size: .small,
                            onPressed: viewModel.maxAmountPressed.send
                        )
                        .transition(.opacity.animation(.easeInOut))
                        .cornerRadius(radius: 32, corners: .allCorners)
                        .frame(width: 68)
                        .padding(.horizontal, 8)
                    }
                }

                Text(viewModel.secondaryAmountText)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .text4)
            }

            Spacer()

            Button(
                action: viewModel.switchPressed.send,
                label: {
                    HStack(spacing: 4) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.mainTokenText)
                                .foregroundColor(Color(mainColor))
                                .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold))

                            Button(
                                action: viewModel.switchPressed.send,
                                label: {
                                    Text(L10n.tapToSwitchTo(viewModel.secondaryCurrencyText))
                                        .foregroundColor(Color(Asset.Colors.mountain.color))
                                        .apply(style: .text4)
                                }
                            )
                        }
                        Image(uiImage: UIImage.arrowUpDown)
                            .renderingMode(.template)
                            .foregroundColor(Color(mainColor))
                            .frame(width: 16, height: 16)
                    }
                }
            )
        }
        .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 12))
        .background(RoundedRectangle(cornerRadius: 12))
        .foregroundColor(Color(Asset.Colors.snow.color))
        .frame(height: 90)
    }

    var oldBody: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        SendInputAmountField(
                            text: $viewModel.amountText,
                            isFirstResponder: $viewModel.isFirstResponder,
                            textColor: $viewModel.amountTextColor
                        ) { textField in
                            textField.font = .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold)
                            textField.placeholder = "0"
                            textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                        }

                        if viewModel.amountText.isEmpty {
                            TextButtonView(
                                title: L10n.max.uppercased(),
                                style: .second,
                                size: .small,
                                onPressed: viewModel.maxAmountPressed.send
                            )
                            .transition(.opacity.animation(.easeInOut))
                            .cornerRadius(radius: 32, corners: .allCorners)
                            .frame(width: 68)
                            .padding(.horizontal, 8)
                        }

                        Spacer()

                        Text(viewModel.mainTokenText)
                            .foregroundColor(Color(mainColor))
                            .font(uiFont: .systemFont(ofSize: UIFont.fontSize(of: .title2), weight: .bold))
                    }
                    HStack(spacing: 0) {
                        Text(viewModel.secondaryAmountText)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                        Spacer()
                        Text(L10n.tapToSwitchTo(viewModel.secondaryCurrencyText))
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .apply(style: .text4)
                    }
                }
                Button(
                    action: viewModel.switchPressed.send,
                    label: {
                        Image(uiImage: UIImage.arrowUpDown)
                            .renderingMode(.template)
                            .foregroundColor(Color(mainColor))
                            .frame(width: 16, height: 16)
                    }
                )
                .frame(width: 24, height: 24)
            }
            .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 12))
            .background(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(Color(Asset.Colors.snow.color))
            .frame(height: 90)
        }
    }
}

struct SendInputAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
            SendInputAmountView(
                viewModel: SendInputAmountViewModel()
            )
            .padding(.horizontal, 16)
        }
    }
}
