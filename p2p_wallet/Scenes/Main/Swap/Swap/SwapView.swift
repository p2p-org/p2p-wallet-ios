import KeyAppUI
import SwiftUI

struct SwapView: View {
    @ObservedObject var viewModel: SwapViewModel

    @State private var animatedFinish: Bool = false

    var body : some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .onTapGesture {
                    viewModel.fromTokenViewModel.isFirstResponder = false
                    viewModel.toTokenViewModel.isFirstResponder = false
                }

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
                        SwapInputView(viewModel: viewModel.fromTokenViewModel)
                        SwapInputView(viewModel: viewModel.toTokenViewModel)
                    }
                    SwapSwitchButton(action: viewModel.switchTokens)
                }
                .padding(.top, 36)

                Text(L10n.keyAppDoesnTMakeAnyProfitFromSwap💚)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.top, 16)

                Spacer()

                SliderActionButton(viewModel: viewModel.actionButtonViewModel)
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct SwapView_Previews: PreviewProvider {
    static var previews: some View {
        SwapView(viewModel: SwapViewModel())
    }
}
