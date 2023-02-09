import KeyAppUI
import SwiftUI

struct SwapView: View {
    @ObservedObject var viewModel: SwapViewModel

    @State private var animatedFinish: Bool = false

    var body : some View {
        ZStack {
            Color(Asset.Colors.smoke.color)

            VStack(spacing: .zero) {
                Text(viewModel.header)
                    .apply(style: .label1)
                    .padding(.top, 4)
                    .foregroundColor(Color(Asset.Colors.night.color))

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
