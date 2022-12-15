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
                if viewModel.isLoading {
                    loading
                } else {
                    if viewModel.hasError {
                        error
                    } else {
                        SellInputView(viewModel: viewModel)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) { Text("Cash out SOL").fontWeight(.semibold) }
        }
    }

    var error: some View {
        VStack(spacing: 8) {
            Image(uiImage: UIImage.coins)
                .padding(.bottom, 12)
            Text("You need a little more SOL")
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.bold)
                .apply(style: .title1)
                .padding(.horizontal, 36)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Text("The current minimum amount  is 2 SOL")
                .foregroundColor(Color(Asset.Colors.night.color))
                .apply(style: .text1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
            TextButtonView(
                title: "Go to Swap",
                style: .primaryWhite,
                size: .large
            ) { [weak viewModel] in
                viewModel?.goToSwap()
            }
            .frame(height: 56)
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 16)
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
