import SwiftUI
import KeyAppUI

struct SendInputActionButtonView: View {
    @ObservedObject private var viewModel: SendInputActionButtonViewModel

    init(viewModel: SendInputActionButtonViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.showFinished {
                Circle()
                    .stroke(Color(Asset.Colors.night.color), lineWidth: 4)
                    .background(Circle().fill(Color(Asset.Colors.lime.color)))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(uiImage: .check)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    )
            } else {
                if viewModel.actionButton.isEnabled {
                    SliderButtonView(
                        title: viewModel.actionButton.title,
                        image: .arrowRight,
                        style: .solidBlack,
                        isOn: .init(get: { [weak viewModel] in
                            viewModel?.isSliderOn ?? false
                        }, set: { [weak viewModel] val in
                            withAnimation {
                                viewModel?.showFinished = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    viewModel?.isSliderOn = val
                                }
                            }
                        })
                    )
                }
                else {
                    TextButtonView(title: viewModel.actionButton.title, style: .primary, size: .large)
                        .disabled(true)
                        .cornerRadius(radius: 32, corners: .allCorners)
                }
            }
        }
        .frame(height: TextButton.Size.large.height)
        .disabled(!viewModel.actionButton.isEnabled)
        .allowsHitTesting(viewModel.actionButton.isEnabled)
        .transition(.asymmetric(insertion: .scale, removal: .scale).combined(with: .opacity))
        .animation(.default, value: viewModel.showFinished)
        .padding(.top, 8)
    }
}

