import KeyAppUI
import SwiftUI

struct SwapView: View {
    @ObservedObject var viewModel: SwapViewModel
    @ObservedObject var fromViewModel: SwapInputViewModel
    @ObservedObject var toViewModel: SwapInputViewModel

    @State private var animatedFinish: Bool = false

    var body : some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .onTapGesture { UIApplication.shared.endEditing() }

            switch viewModel.initializingState {
            case .loading, .success:
                contentView
            case .failed:
                errorView
            }
        }
    }
}

private extension SwapView {
    var contentView: some View {
        VStack(spacing: .zero) {
            Text(viewModel.header)
                .apply(style: .label1)
                .padding(.top, 4)
                .foregroundColor(Color(Asset.Colors.night.color))
                .if(viewModel.arePricesLoading) { view in
                    view.skeleton(with: true, size: CGSize(width: 160, height: 16))
                }
                .frame(height: 16)

            ZStack {
                VStack(spacing: 8) {
                    SwapInputView(viewModel: fromViewModel)
                    SwapInputView(viewModel: toViewModel)
                }
                SwapSwitchButton(action: viewModel.switchTokens)
            }
            .padding(.top, 36)

            Text(L10n.keyAppDoesnTMakeAnyProfitFromSwap💚)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, 16)

            Spacer()
            
            SliderActionButton(
                isSliderOn: $viewModel.isSliderOn,
                data: $viewModel.actionButtonData,
                showFinished: $viewModel.showFinished
            )
            .padding(.bottom, 36)
        }
        .padding(.horizontal, 16)
    }

    var errorView: some View {
        BaseErrorView(
            appearance: BaseErrorView.Appearance(actionButtonHorizontalOffset: 16, imageTextPadding: 20),
            actionTitle: L10n.tryAgain,
            action: viewModel.tryAgain.send
        )
    }
}
