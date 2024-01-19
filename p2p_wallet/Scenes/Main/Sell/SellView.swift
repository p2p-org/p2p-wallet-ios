import SkeletonUI
import SwiftUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
        ZStack {
            Color(.smoke)
                .edgesIgnoringSafeArea(.all)
            VStack {
                switch viewModel.status {
                case .loading:
                    loading
                case .ready:
                    SellInputView(viewModel: viewModel)
                case .error(.other):
                    BaseErrorView(
                        appearance: BaseErrorView.Appearance(
                            actionButtonHorizontalOffset: 23,
                            imageTextPadding: 30
                        ),
                        actionTitle: L10n.goBack
                    ) {
                        viewModel.goBack()
                    }
                case let .error(.region(model)):
                    ChangeCountryErrorView(
                        model: model,
                        buttonAction: {
                            viewModel.goBack()
                        },
                        subButtonAction: {
                            viewModel.changeTheRegionClicked()
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.appeared()
        }
        .onForeground {
            viewModel.isEnteringBaseAmount = !viewModel.shouldNotShowKeyboard
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Spacer()
                    Spacer()
                    Text(L10n.cashoutWithMoonpay)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(
                        action: {
                            viewModel.changeTheRegionClicked()
                        },
                        label: {
                            HStack(spacing: 10) {
                                Text(viewModel.region?.flag ?? .neutralFlag)
                                    .font(uiFont: .font(of: .title1, weight: .bold))
                                Image(.chevronDown)
                                    .foregroundColor(Color(.mountain))
                            }
                        }
                    )
                }
            }
        }
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
