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
                .ignoresSafeArea()

            switch viewModel.initializingState {
            case .loading, .success:
                VStack {
                    ScrollViewReader { value in
                        ScrollView {
                            contentView
                        }
                        .onChange(of: viewModel.currentState.priceImpact, perform: { priceImpact in
                            guard priceImpact != nil else { return }
                            value.scrollTo("\(SwapPriceImpactView.self)")
                        })
                        .scrollDismissesKeyboard()
                    }
                    Spacer()

                    SliderActionButton(
                        isSliderOn: $viewModel.isSliderOn,
                        data: $viewModel.actionButtonData,
                        showFinished: $viewModel.showFinished
                    )
                    .accessibilityIdentifier("SwapView.sliderButton")
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 16)
            case .failed:
                errorView
            }
        }
    }
}

private extension SwapView {
    var contentView: some View {
        VStack(spacing: .zero) {
            // Header
            Text(viewModel.header)
                .apply(style: .label1)
                .padding(.top, 4)
                .foregroundColor(Color(Asset.Colors.night.color))
                .accessibilityIdentifier("SwapView.priceInfoLabel")
                .if(viewModel.arePricesLoading) { view in
                    view.skeleton(with: true, size: CGSize(width: 160, height: 16))
                }
                .frame(height: 16)

            // Inputs
            ZStack {
                VStack(spacing: 8) {
                    SwapInputView(viewModel: fromViewModel)
                    SwapInputView(viewModel: toViewModel)
                }
                SwapSwitchButton(action: viewModel.switchTokens)
            }
            .padding(.top, 36)

            #if !RELEASE
            // Route (for debugging)
            Text("Route: " + (viewModel.getRouteInSymbols()?.joined(separator: " -> ") ?? ""))
                .apply(style: .label2)
                .foregroundColor(.red)
            
            // Slippage (for debugging)
            Text("Slippage: \(Double(viewModel.stateMachine.currentState.slippage) / 100)%")
                .apply(style: .label2)
                .foregroundColor(.red)
            #endif

            // Disclaimer
            Text(L10n.keyAppDoesnTMakeAnyProfitFromSwap💚)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, 16)
                .accessibilityIdentifier("SwapView.profitInfoLabel")

            // Price impact
            if let priceImpact = viewModel.currentState.priceImpact {
                SwapPriceImpactView(priceImpact: priceImpact)
                    .padding(.top, 23)
                    .accessibilityIdentifier("SwapView.priceImpactView")
                    .id("\(SwapPriceImpactView.self)")
            }

            Spacer()

            #if !RELEASE
            // Logs (for debugging)
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
        .onTapGesture { UIApplication.shared.endEditing() }
    }

    var errorView: some View {
        BaseErrorView(
            appearance: BaseErrorView.Appearance(actionButtonHorizontalOffset: 16, imageTextPadding: 20),
            actionTitle: L10n.tryAgain,
            action: viewModel.tryAgain.send
        )
    }
}
