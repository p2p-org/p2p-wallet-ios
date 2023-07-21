import KeyAppUI
import SwiftUI

struct WithdrawCalculatorView: View {
    @ObservedObject var viewModel: WithdrawCalculatorViewModel

    var body: some View {
        ColoredBackground {
            VStack {
                ScrollView {
                    contentView
                }
                .safeAreaInset(edge: .bottom, content: {
                    NewTextButton(
                        title: viewModel.actionData.title,
                        style: .primaryWhite,
                        expandable: true,
                        isEnabled: viewModel.actionData.isEnabled,
                        isLoading: viewModel.isLoading,
                        trailing: viewModel.actionData.isEnabled ? .arrowForward
                            .withRenderingMode(.alwaysTemplate) : nil,
                        action: viewModel.actionPressed.send
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                    .background(Color(Asset.Colors.smoke.color).edgesIgnoringSafeArea(.bottom))
                })
                .scrollDismissesKeyboard()
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // We need delay because BigInputView is UITextField
                viewModel.isFromFirstResponder = true
            }
        }
    }

    var contentView: some View {
        VStack(spacing: .zero) {
            // Header
            headerText

            // Inputs
            ZStack {
                VStack(spacing: 8) {
                    fromInput
                    toInput
                }

                WithdrawCalculatorSwapIcon()
            }
            .padding(.top, 36)

            // Disclaimer
            disclaimerText
        }
        .onTapGesture { UIApplication.shared.endEditing() }
    }

    var headerText: some View {
        Text(viewModel.exchangeRatesInfo)
            .apply(style: .label1)
            .padding(.top, 4)
            .foregroundColor(Color(Asset.Colors.night.color))
            .if(viewModel.arePricesLoading) { view in
                view.skeleton(with: true, size: CGSize(width: 160, height: 16))
            }
            .frame(height: 16)
    }

    var fromInput: some View {
        BigInputView(
            allButtonPressed: viewModel.allButtonPressed.send,
            amountFieldTap: nil,
            changeTokenPressed: nil,
            accessibilityIdPrefix: "\(WithdrawCalculatorView.self).from",
            title: L10n.youPay,
            isBalanceVisible: false,
            amount: $viewModel.fromAmount,
            amountTextColor: $viewModel.fromAmountTextColor,
            isFirstResponder: $viewModel.isFromFirstResponder,
            decimalLength: $viewModel.decimalLength,
            isEditable: $viewModel.isFromEnabled,
            balance: $viewModel.fromBalance,
            balanceText: $viewModel.fromBalanceText,
            tokenSymbol: $viewModel.fromTokenSymbol,
            isAmountLoading: $viewModel.arePricesLoading
        )
    }

    var toInput: some View {
        BigInputView(
            allButtonPressed: nil,
            amountFieldTap: nil,
            changeTokenPressed: nil,
            accessibilityIdPrefix: "\(WithdrawCalculatorView.self).to",
            title: L10n.youReceive,
            isBalanceVisible: false,
            amount: $viewModel.toAmount,
            isFirstResponder: $viewModel.isToFirstResponder,
            decimalLength: $viewModel.decimalLength,
            isEditable: $viewModel.isToEnabled,
            balance: .constant(nil),
            balanceText: .constant(""),
            tokenSymbol: $viewModel.toTokenSymbol,
            isAmountLoading: $viewModel.arePricesLoading
        )
    }

    var disclaimerText: some View {
        Text(L10n.forThisTransferTheExchangeRateIsnTGuaranteedWeWillUseTheRateAtTheMomentOfReceivingMoney)
            .apply(style: .label1)
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .padding(.top, 16)
    }
}

struct WithdrawCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WithdrawCalculatorView(viewModel: WithdrawCalculatorViewModel())
        }.navigationTitle(L10n.withdraw)
    }
}
