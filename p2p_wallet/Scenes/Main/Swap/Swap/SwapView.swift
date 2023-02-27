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
                ScrollView {
                    contentView
                }
                .customRefreshable {
                    await viewModel.update()
                }
                .scrollDismissesKeyboard()
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
                .accessibilityIdentifier("SwapView.priceInfoLabel")
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
            
            #if !RELEASE
            Text("Route: " + (viewModel.getRouteInSymbols()?.joined(separator: " -> ") ?? ""))
                .apply(style: .label2)
                .foregroundColor(.red)
            #endif

            Text(L10n.keyAppDoesnTMakeAnyProfitFromSwap💚)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, 16)
                .accessibilityIdentifier("SwapView.profitInfoLabel")

            Spacer()
            
            SliderActionButton(
                isSliderOn: $viewModel.isSliderOn,
                data: $viewModel.actionButtonData,
                showFinished: $viewModel.showFinished
            )
            .accessibilityIdentifier("SwapView.sliderButton")
            .padding(.bottom, 36)
            
            #if !RELEASE
            VStack(alignment: .leading, spacing: 10) {
                Text("Logs (tap to copy and clear):")
                    .apply(style: .label2)
                if let swapTransaction = viewModel.swapTransaction {
                    Text("Transaction:")
                        .apply(style: .label2)
                    Text(swapTransaction)
                        .apply(style: .label2)
                }
                
                if let errorLogs = viewModel.errorLogs {
                    Text("ERROR:")
                        .apply(style: .label2)
                    VStack(alignment: .leading) {
                        ForEach(errorLogs, id: \.self) { log in
                            Text(log)
                                .apply(style: .label2)
                        }
                    }
                }
            }
                .foregroundColor(.red)
                .onTapGesture {
                    viewModel.copyAndClearLogs()
                }
            
            #endif
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
