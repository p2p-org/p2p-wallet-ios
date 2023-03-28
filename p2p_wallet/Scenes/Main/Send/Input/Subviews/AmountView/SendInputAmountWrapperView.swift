import KeyAppUI
import SwiftUI

// This view is a wrapper since it is extracted in another common view SendInputAmountView. Right now it is needed because it is binded to SendInputAmountViewModel. The logic of binding should be changed in order to remove this wrapper.
struct SendInputAmountWrapperView: View {
    @ObservedObject private var viewModel: SendInputAmountViewModel

    init(viewModel: SendInputAmountViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        SendInputAmountView(
            amountText: $viewModel.amountText,
            isFirstResponder: $viewModel.isFirstResponder,
            amountTextColor: viewModel.amountTextColor,
            countAfterDecimalPoint: viewModel.countAfterDecimalPoint,
            mainTokenText: viewModel.mainTokenText,
            secondaryAmountText: viewModel.secondaryAmountText,
            secondaryCurrencyText: viewModel.secondaryCurrencyText,
            maxAmountPressed: viewModel.maxAmountPressed,
            switchPressed: viewModel.switchPressed,
            isDisabled: viewModel.isDisabled,
            isMaxButtonVisible: viewModel.isMaxButtonVisible,
            isSwitchMainAmountTypeAvailable: viewModel.isSwitchMainAmountTypeAvailable
        )
    }
}

struct SendInputAmountWrapperView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
            SendInputAmountWrapperView(
                viewModel: SendInputAmountViewModel(initialToken: .init(token: .nativeSolana), allowSwitchingMainAmountType: false)
            )
            .padding(.horizontal, 16)
        }
    }
}
