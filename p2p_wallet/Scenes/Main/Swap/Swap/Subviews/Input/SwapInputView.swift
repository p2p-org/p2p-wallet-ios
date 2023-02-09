import KeyAppUI
import SwiftUI

struct SwapInputView: View {

    @ObservedObject var viewModel: SwapInputViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.title)
                    .subtitleStyle()

                Spacer()

                if viewModel.isEditable && viewModel.balanceText != nil && !viewModel.isLoading  {
                    allButton
                }
            }
            HStack {
                changeTokenButton

                Spacer()

                amountField
            }
            HStack {
                balanceLabel

                Spacer()

                if let fiatAmount = viewModel.fiatAmount, !viewModel.isLoading {
                    Text("≈\(fiatAmount)")
                        .subtitleStyle()
                }
            }
            .frame(minHeight: 16)
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(Asset.Colors.snow.color).opacity(viewModel.isEditable ? 1 : 0.6)))
    }
}

// MARK: - Subviews
private extension SwapInputView {

    var allButton: some View {
        Button(action: viewModel.allButtonPressed.send, label: {
            HStack(spacing: 4) {
                Text(L10n.all.uppercaseFirst)
                    .subtitleStyle()
                Text(viewModel.balanceText ?? "")
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.sky.color))
            }
        })
    }

    var changeTokenButton: some View {
        Button {
            viewModel.changeTokenPressed.send()
        } label: {
            HStack {
                Text(viewModel.tokenSymbol)
                    .apply(style: .title1)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .if(viewModel.isLoading) { view in
                        view.skeleton(with: true, size: CGSize(width: 84, height: 20))
                    }
                Image(uiImage: .expandIcon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }

    var amountField: some View {
        FocusedTextField(text: $viewModel.amountText, isFirstResponder: $viewModel.isFirstResponder) { textField in
            textField.font = .font(of: .title1)
            textField.textColor = Asset.Colors.night.color
            textField.keyboardType = .decimalPad
            textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            textField.isEnabled = viewModel.isEditable
            textField.placeholder = "0"
        }
        .if(viewModel.isLoading) { view in
            view.skeleton(with: true, size: CGSize(width: 84, height: 20))
        }
        .frame(height: 32)
    }

    var balanceLabel: some View {
        Text("\(L10n.balance) \(viewModel.balanceText ?? "0")")
            .subtitleStyle()
            .if(viewModel.isLoading) { view in
                view.skeleton(with: true, size: CGSize(width: 84, height: 8))
            }
    }
}

private extension Text {
    func subtitleStyle() -> some View {
        return self.apply(style: .label1).foregroundColor(Color(UIColor._9799Af))
    }
}
