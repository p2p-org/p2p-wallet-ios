import SwiftUI
import KeyAppUI

struct WithdrawCalculatorView: View {
    @ObservedObject var viewModel: WithdrawCalculatorViewModel

    var body: some View {
        ColoredBackground {
            VStack {
                ScrollView {
                    contentView
                }
                .scrollDismissesKeyboard()

                Spacer()

                NewTextButton(
                    title: L10n.next.uppercaseFirst,
                    style: .primaryWhite,
                    expandable: true,
                    isLoading: false,
                    trailing: .arrowForward.withRenderingMode(.alwaysTemplate),
                    action: viewModel.nextPressed.send
                )
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 16)
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
            allButtonPressed: { },
            amountFieldTap: nil,
            changeTokenPressed: nil,
            accessibilityIdPrefix: "\(WithdrawCalculatorView.self).from",
            title: L10n.youPay,
            isBalanceVisible: false,
            amount: $viewModel.fromAmount,
            isFirstResponder: $viewModel.isFromFirstResponder,
            decimalLength: $viewModel.fromDecimalLength,
            balance: $viewModel.fromBalance,
            balanceText: .constant(""),
            tokenSymbol: $viewModel.fromTokenSymbol
        )
    }

    var toInput: some View {
        BigInputView(
            allButtonPressed: { },
            amountFieldTap: nil,
            changeTokenPressed: nil,
            accessibilityIdPrefix: "\(WithdrawCalculatorView.self).to",
            title: L10n.youReceive,
            isBalanceVisible: false,
            amount: $viewModel.toAmount,
            isFirstResponder: $viewModel.isToFirstResponder,
            decimalLength: $viewModel.toDecimalLength,
            balance: .constant(nil),
            balanceText: .constant(""),
            tokenSymbol: $viewModel.toTokenSymbol
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
