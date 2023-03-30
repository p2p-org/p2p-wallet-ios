import KeyAppUI
import SkeletonUI
import SolanaSwift
import SwiftUI

struct BuyView: View, KeyboardVisibilityReadable {
    private let textLeadingPadding = 25.0
    private let cardLeadingPadding = 16.0

    // MARK: -

    @ObservedObject var viewModel: BuyViewModel
    /// Bottom button view offset
    @State var bottomOffset = CGFloat(110)
    @State var leftInputText: String = ""
    @State var rightInputText: String = ""
    @State private var isKeyboardVisible = false

    init(viewModel: BuyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                // Tutorial
                if let targetSymbol = viewModel.targetSymbol {
                    BuyTips(sourceSymbol: viewModel.token.symbol, destinationSymbol: targetSymbol)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Spacer()
                            icon
                                .padding(.top, 12)
                            Spacer()
                        }
                        input
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                            .onReceive(isKeyboardShown) { isKeyboardVisible in
                                self.isKeyboardVisible = isKeyboardVisible
                            }
                        Divider()
                            .frame(height: 1)
                            .overlay(Color(Asset.Colors.snow.color))
                        if viewModel.availableMethods.count > 1 || viewModel.areMethodsLoading {
                            methods
                                .padding(.top, 22)
                        }
                        
                        total
                            .padding(.top, 26)
                    }
                    .background(Color(Asset.Colors.rain.color))
                    .cornerRadius(20)
                    .padding([.leading, .trailing], 16)
                    if !viewModel.isLeftFocus, !viewModel.isRightFocus {
                        poweredBy
                    }
                }
                .offset(y: min(20, 20 * UIScreen.main.bounds.height / 812))
            }.onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }.onTapGesture {
                UIApplication.shared.keyWindow?.endEditing(true)
            }
            Spacer()
            actionButtonView
        }
        .toolbar {
            ToolbarItem(placement: .principal) { Text(L10n.buyWithMoonpay).fontWeight(.semibold) }
        }
        .onAppear {
            withAnimation {
//                viewModel.navigationSlidingPercentage = 0
                bottomOffset = 0
            }
        }
        .ignoresSafeArea(.keyboard, edges: isKeyboardVisible ? .top : .bottom)
    }

    var poweredBy: some View {
        VStack(spacing: 4) {
            Text(L10n.poweredBy + " Moonpay")
                .apply(style: .label1)
                .foregroundColor(Color(UIColor._9799Af))
            Button {
                viewModel.moonpayLicenseTap()
            } label: {
                Text(L10n.license)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }

    var icon: some View {
        Image(uiImage: UIImage.buyIcon)
            .resizable()
            .scaledToFit()
            .frame(height: 48)
    }

    var input: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            }
            .padding(.horizontal, 16)
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
                                .frame(width: 158, height: 100)
                            skeletonMethod()
                                .frame(width: 158, height: 100)
                        } else {
                            ForEach(viewModel.availableMethods, id: \.name) { item in
                                Button { [weak viewModel] in
                                    viewModel?.didSelectPayment(item)
                                    UIApplication.shared.keyWindow?.endEditing(true)
                                    withAnimation {
                                        scrollView.scrollTo(item.type, anchor: .center)
                                    }
                                } label: {
                                    methodCard(item: item)
                                        .accessibilityIdentifier("BuyView.methods" + (item.type == viewModel.selectedPayment ? "_selected" : item.type.rawValue))
                                        .foregroundColor(Color(Asset.Colors.night.color))
                                        .frame(width: 158)
                                }.addBorder(
                                    item.type == viewModel.selectedPayment ?
                                        Color(Asset.Colors.night.color) :
                                        Color.clear, width: 1, cornerRadius: 16
                                ).id(item.type)
                            }
                        }
                    }.padding(.horizontal, 17)
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
                        .accessibilityIdentifier("BuyView.total")
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
                top: 14,
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
                bottom: 13,
                trailing: 0
            ))
        }
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
//        .frame(width: 151, height: 100)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(16)
    }

    private var actionButtonView: some View {
        TextButtonView(
            title: viewModel.buttonItem.title,
            style: .primaryWhite,
            size: .large,
            trailing: viewModel.buttonItem.icon?.withTintColor(Asset.Colors.rain.color)
        ) { [weak viewModel] in
            viewModel?.buyButtonTapped()
        }
        .frame(height: 56)
        .accessibilityIdentifier("BuyView.actionButtonView")
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
        .disabled(!viewModel.buttonItem.enabled)
    }
}
