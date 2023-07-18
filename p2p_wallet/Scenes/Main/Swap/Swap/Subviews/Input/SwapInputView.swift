import Foundation
import KeyAppUI
import SwiftUI
import SolanaSwift

struct SwapInputView: View {

    @ObservedObject var viewModel: SwapInputViewModel

    var body: some View {
        BigInputView(
            allButtonPressed: { viewModel.allButtonPressed.send() },
            amountFieldTap: { viewModel.amountFieldTap.send() },
            changeTokenPressed: { viewModel.changeTokenPressed.send() },
            accessibilityIdPrefix: viewModel.accessibilityIdentifierTokenPrefix,
            title: viewModel.title,
            amount: $viewModel.amount,
            amountTextColor: $viewModel.amountTextColor,
            isFirstResponder: $viewModel.isFirstResponder,
            decimalLength: $viewModel.decimalLength,
            isEditable: $viewModel.isEditable,
            balance: $viewModel.balance,
            balanceText: $viewModel.balanceText,
            tokenSymbol: $viewModel.tokenSymbol,
            isLoading: $viewModel.isLoading,
            isAmountLoading: $viewModel.isAmountLoading,
            fiatAmount: $viewModel.fiatAmount,
            fiatAmountTextColor: $viewModel.fiatAmountTextColor
        )
    }
}
