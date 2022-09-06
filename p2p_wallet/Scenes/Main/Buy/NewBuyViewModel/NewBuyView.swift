import KeyAppUI
import SolanaSwift
import SwiftUI

struct NewBuyView: View {
    private let textLeadingPadding = 24.0
    private let cardLeadingPadding = 16.0

    // MARK: -

    @ObservedObject var viewModel: NewBuyViewModel

    init(viewModel: NewBuyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    // Logo
                    HStack {
                        Spacer()
                        icon
                            .padding(.top, 13)
                            .padding(.trailing, 3)
                        Spacer()
                    }

                    // Input
                    input
                        .padding(.top, 2)
                        .padding(.horizontal, 16)

                    // Payment method
                    methods
                        .padding(.top, 9)

                    // Total
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
        }
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

            BuyInputOutputView(
                leftTitle: $viewModel.cryptoInput,
                leftSubtitle: viewModel.cryptoValue.formattedConcurrency,
                rightTitle: $viewModel.fiatInput,
                rightSubtitle: viewModel.fiatValue.formattedConcurrency
            )
        }
    }

    var methods: some View {
        VStack(alignment: .leading) {
            Text("Method")
                .apply(style: .text3)
                .padding(.leading, textLeadingPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.paymentMethods, id: \.self) { item in
                        Button {
                            viewModel.selectedPaymentMethod = item
                        }
                        label: {
                            BuyPaymentMethodView(payment: item, selected: viewModel.selectedPaymentMethod == item)
                        }
                    }
                }.padding(.horizontal, 16)
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
            } else {
                Button { [weak viewModel] in viewModel?.showDetail() }
                label: {
                        Text("\(viewModel.total.formattedValue) \(viewModel.total.formattedConcurrency)")
                            .apply(style: .text3)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                        Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    }
            }
        }.padding(EdgeInsets(top: 0, leading: 24, bottom: 18, trailing: 29))
    }

    func inputView(
        text: Binding<String>,
        coin: String,
        onEditing: @escaping (Bool) -> Void,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 4) {
            TextField("", text: text, onEditingChanged: { vall in
                onEditing(vall)
            })
                .multilineTextAlignment(.trailing)
            Group {
                Text(coin)
                    .apply(style: .title2)
                    .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                    .padding(.trailing, 1)
                Image(uiImage: Asset.MaterialIcon.arrowDropDown.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(.trailing, 10)
            }.onTapGesture {
                action()
            }
        }
        .frame(height: 62)
        .background(Color(Asset.Colors.snow.color))
    }
}

extension NewBuyView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                // Create a wallet
                TextButtonView(
                    title: L10n.buy,
                    style: .inverted,
                    size: .large,
                    trailing: UIImage.buyWallet
                ) {}
            }
        }
    }
}

struct NewBuyView_Previews: PreviewProvider {
    static var previews: some View {
        NewBuyView(viewModel: .init())
    }
}
