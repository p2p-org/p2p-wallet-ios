import SwiftUI
import KeyAppUI
import SkeletonUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack {
                switch viewModel.status {
                case .initialized, .updating:
                    loading
                case .ready:
                    SellInputView(viewModel: viewModel)
                case .error:
                    BaseErrorView(
                        appearance: .init(actionButtonHorizontalOffset: 23, imageTextPadding: 30),
                        actionTitle: L10n.goBack
                    ) {
                        viewModel.goBack()
                    }
                }
            }
        }
        .onAppear {
            viewModel.appeared()
        }
        .onForeground {
            viewModel.isEnteringBaseAmount = !viewModel.shouldNotShowKeyboard
        }
        .navigationBarTitle("\(L10n.cashOut) SOL", displayMode: .large)
    }

    var loading: some View {
        VStack(spacing: 8) {
            Text("").frame(height: 44)
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 44))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Text("").frame(height: 44).skeleton(with: true, size: .init(width: CGFloat.infinity, height: 44))
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Text("").frame(height: 98).skeleton(with: true, size: .init(width: CGFloat.infinity, height: 98))
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
            Spacer()
            Text("")
                .padding(.bottom, 60)
                .skeleton(with: true, size: .init(width: CGFloat.infinity, height: 56))
                .shape(type: .rounded(.radius(12, style: .circular)))
                .padding(.bottom, 10)
        }
            .padding(.top, 90)
            .padding(.horizontal, 16)
    }
}
