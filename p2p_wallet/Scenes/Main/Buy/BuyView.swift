import KeyAppUI
import SkeletonUI
import SolanaSwift
import SwiftUI

struct BuyView: View {
    private let textLeadingPadding = 24.0
    private let cardLeadingPadding = 16.0

    // MARK: -

    @ObservedObject var viewModel: BuyViewModel
//    @State var bottomOffset = CGFloat.zero
    @State var leftInputText: String = ""
    @State var rightInputText: String = ""

    init(viewModel: BuyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        icon
                            .padding(.top, 13)
                            .padding(.trailing, 3)
                        Spacer()
                    }
                    input
                        .padding(.top, 2)
                        .padding(.bottom, 24)
                    Divider()
                        .frame(height: 1)
                        .overlay(Color(Asset.Colors.snow.color))
                    if viewModel.availableMethods.count > 1 || viewModel.areMethodsLoading {
                        methods
                            .padding(.top, 20)
                    }

                    total
                        .padding(.top, 18)
                }
                .background(Color(Asset.Colors.rain.color))
                .cornerRadius(20)
                .padding([.leading, .trailing], 16)
                .offset(y: 30)
            }.onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }.onTapGesture {
                UIApplication.shared.keyWindow?.endEditing(true)
            }
            Spacer()
            bottomActionsView
                .frame(height: 110)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle(L10n.buy)
    }

    var icon: some View {
        Image("buy-icon")
    }

    var input: some View {
        VStack(alignment: .leading) {
            Text(L10n.buying)
                .apply(style: .text3)
                .padding(.leading, textLeadingPadding)

            BuyInputOutputView(
                leftTitle: $viewModel.tokenAmount,
                leftSubtitle: viewModel.token.symbol,
                rightTitle: $viewModel.fiatAmount,
                rightSubtitle: viewModel.fiat.code,
                activeSide: .init(get: {
                    if viewModel.isLeftFocus == false, viewModel.isRightFocus == false {
                        return .none
                    } else if viewModel.isLeftFocus == true {
                        return .left
                    } else {
                        return .right
                    }
                }, set: { side in
                    switch side {
                    case .left:
                        viewModel.isLeftFocus = true
                        viewModel.isRightFocus = false
                    case .right:
                        viewModel.isLeftFocus = false
                        viewModel.isRightFocus = true
                    case .none:
                        viewModel.isLeftFocus = false
                        viewModel.isRightFocus = false
                    }
                })
            ) { sideTap in
                switch sideTap {
                case .left: viewModel.tokenSelectTapped()
                case .right: viewModel.fiatSelectTapped()
                case .none: return
                }
            }.padding(.horizontal, 16)
        }
    }

    var methods: some View {
        VStack(alignment: .leading) {
            Text(L10n.method)
                .apply(style: .text3)
                .padding(.leading, textLeadingPadding)
            ScrollViewReader { scrollView in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if viewModel.areMethodsLoading {
                            skeletonMethod()
                            skeletonMethod()
                        } else {
                            ForEach(viewModel.availableMethods, id: \.name) { item in
                                Button { [weak viewModel] in
                                    viewModel?.didSelectPayment(item)
                                    withAnimation {
                                        scrollView.scrollTo(item.type, anchor: .center)
                                    }
                                } label: {
                                    methodCard(item: item)
                                        .foregroundColor(Color(Asset.Colors.night.color))
                                }.addBorder(
                                    item.type == viewModel.selectedPayment ?
                                        Color(Asset.Colors.night.color) :
                                        Color.clear, width: 1, cornerRadius: 16
                                ).id(item.type)
                            }
                        }
                    }.padding(.horizontal, 16)
                }
            }
        }
    }

    var total: some View {
        HStack {
            Text(L10n.total)
                .apply(style: .text3)
            Spacer()
            if viewModel.isLoading {
                ActivityIndicator(isAnimating: true)
                    .frame(height: 24)
            } else {
                Button { [weak viewModel] in
                    Task { try await viewModel?.totalTapped() }
                } label: {
                    Text("\(viewModel.total)")
                        .apply(style: .text3)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }
        }.padding(EdgeInsets(top: 0, leading: 24, bottom: 18, trailing: 29))
    }

    func methodCard(item: BuyViewModel.PaymentTypeItem) -> some View {
        VStack(alignment: .leading) { [weak viewModel] in
            HStack {
                HStack(alignment: .bottom) {
                    Text(item.fee)
                        .apply(style: .title2)

                    Text(L10n.fee)
                        .apply(style: .label1)
                        .padding(.bottom, 3)
                        .padding(.leading, -4)
                    Spacer()
                }
                Spacer()
                if viewModel?.selectedPayment == item.type {
                    Image("checkmark-filled")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .padding(.trailing, 13)
                        .padding(.top, -3)
                } else {
                    Image("checkmark-empty")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .padding(.trailing, 13)
                        .padding(.top, -3)
                }
            }.padding(EdgeInsets(
                top: 13,
                leading: cardLeadingPadding,
                bottom: 0,
                trailing: 0
            ))

            Text(item.duration)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, -9)
                .padding(.leading, cardLeadingPadding)

            HStack(alignment: .top) {
                Text(item.name)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Image(uiImage: item.icon)
                    .padding(.leading, -4)
                    .padding(.top, -1)
                Spacer()
            }.padding(EdgeInsets(
                top: 5,
                leading: cardLeadingPadding,
                bottom: 12,
                trailing: 0
            ))
        }
        .frame(width: 145)
        .background(Color(Asset.Colors.cloud.color))
        .cornerRadius(16)
    }

    func skeletonMethod() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("")
                    .apply(style: .title2)
                    .frame(width: 56, height: 28)
                    .skeleton(
                        with: viewModel.areMethodsLoading,
                        size: CGSize(width: 56, height: 28),
                        animated: .default
                    ).padding(EdgeInsets(
                        top: 12,
                        leading: 16,
                        bottom: 4,
                        trailing: 40
                    ))
                Text("")
                    .apply(style: .label2)
                    .padding(.trailing, 70)
                    .skeleton(
                        with: viewModel.areMethodsLoading,
                        size: CGSize(width: 56, height: 8),
                        animated: .default
                    ).padding(EdgeInsets(
                        top: 12,
                        leading: 16,
                        bottom: 0,
                        trailing: 40
                    ))
                Spacer()
                Text("").apply(style: .title3)
                    .skeleton(
                        with: viewModel.areMethodsLoading,
                        size: CGSize(width: 56, height: 16),
                        animated: .default
                    ).padding(EdgeInsets(
                        top: 0,
                        leading: 16,
                        bottom: 12,
                        trailing: 40
                    ))
            }
            Spacer()
        }
        .frame(width: 151, height: 100)
        .background(Color(Asset.Colors.cloud.color))
        .cornerRadius(16)
    }
}

extension BuyView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                // Create a wallet
                TextButtonView(
                    title: viewModel.buttonTitle,
                    titleBinding: $viewModel.buttonTitle,
                    style: .inverted,
                    size: .large,
                    trailing: UIImage.buyWallet,
                    trailingBinding: $viewModel.buttonIcon,
                    isEnabled: $viewModel.buttonEnabled
                ) { [weak viewModel] in
                    viewModel?.buyButtonTapped()
                }
            }
        }
    }
}
