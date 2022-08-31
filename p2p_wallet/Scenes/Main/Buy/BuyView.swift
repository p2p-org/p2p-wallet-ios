import KeyAppUI
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

                    methods
                        .padding(.top, 9)

                    total
                        .padding(.top, 18)
                }
                .background(Color(Asset.Colors.rain.color))
                .cornerRadius(20)
                .padding([.leading, .trailing], 16)
                .offset(y: 30)
            }
            Spacer()
            bottomActionsView
                .frame(height: 110)
//                .offset(y: bottomOffset)
        }
//        .gesture(
//            DragGesture().onChanged({ gesture in
//                if gesture.startLocation.x > CGFloat(150.0) {
//                    return
//                }
//                print("edge pan \(gesture.location)")
//                print("edge pan \(gesture.translation)")
//                bottomOffset -= gesture.translation.height
//            }).onEnded({ gesture in
//                bottomOffset = .zero
//            })
//        )
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle(L10n.buy)
    }

    var icon: some View {
        Image("buy-icon")
    }

    var input: some View {
        VStack(alignment: .leading) {
            Text("Buying")
                .apply(style: .text3)
                .padding(.leading, textLeadingPadding)

            HStack(alignment: .center, spacing: 1) {
                inputView(text: $leftInputText, coin: viewModel.token.symbol)
                    .cornerRadius(radius: 12, corners: [.topLeft, .bottomLeft])
                    .onTapGesture {
                        viewModel.tokenSelectTapped()
                    }
                inputView(text: $rightInputText, coin: viewModel.fiat.symbol)
                    .cornerRadius(radius: 12, corners: [.topRight, .bottomRight])
                    .onTapGesture {
                        viewModel.fiatSelectTapped()
                    }
            }
            .padding([.leading, .trailing], cardLeadingPadding)
            .padding(.top, -4)
        }
    }

    var methods: some View {
        VStack(alignment: .leading) {
            Text("Method")
                .apply(style: .text3)
                .padding(.leading, textLeadingPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.availableMethods, id: \.name) { item in
                        methodCard(item: item)
                    }
                }.padding([.leading, .trailing], 16)
            }
        }
    }

    var total: some View {
        HStack {
            Text("Total")
                .apply(style: .text3)
            Spacer()
            Button { [weak viewModel] in
                viewModel?.didTapTotal()
            } label: {
                Text("346.4 USD")
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }.padding(EdgeInsets(top: 0, leading: 24, bottom: 18, trailing: 29))
    }

    func methodCard(item: BuyViewModel.PaymentTypeItem) -> some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(alignment: .bottom) {
                    Text(item.fee)
                        .apply(style: .title2)

                    Text("fee")
                        .apply(style: .label1)
                        .padding(.bottom, 3)
                        .padding(.leading, -4)
                    Spacer()
                }

                Spacer()

                Button {} label: {
                    Image("checkmark-empty")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                }
                .padding(.trailing, 13)
                .padding(.top, -3)
            }.padding(EdgeInsets(top: 13, leading: cardLeadingPadding, bottom: 0, trailing: 0))

            Text(item.time)
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
            }.padding(EdgeInsets(top: 5, leading: cardLeadingPadding, bottom: 12, trailing: 0))
        }
        .frame(width: 145)
        .background(Color(Asset.Colors.cloud.color))
        .cornerRadius(16)
    }

    func inputView(text: Binding<String>, coin: String) -> some View {
        HStack(alignment: .center, spacing: 4) {
            TextField("", text: text)
                .multilineTextAlignment(.trailing)
            Text(coin)
                .apply(style: .title2)
                .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                .padding(.trailing, 1)
            Image(uiImage: Asset.MaterialIcon.arrowDropDown.image)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(.trailing, 10)
        }
        .frame(height: 62)
        .background(Color(Asset.Colors.snow.color))
    }
}

extension BuyView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                // Create a wallet
                TextButtonView(
                    title: L10n.buy,
                    style: .inverted,
                    size: .large,
                    trailing: UIImage.buyWallet
                ) { [weak viewModel] in
                }
            }
        }
    }
}
