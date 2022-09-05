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
                inputView(
                    text: $viewModel.tokenAmount,
                    coin: viewModel.token.symbol,
                    onEditing: { val in
                        viewModel.isLeftFocus = val
                    },
                    action: {
                        viewModel.tokenSelectTapped()
                    }).cornerRadius(
                        radius: 12,
                        corners: [.topLeft, .bottomLeft]
                    )

                inputView(
                    text: $viewModel.fiatAmount,
                    coin: viewModel.fiat.symbol,
                    onEditing: { val in
                        viewModel.isRightFocus = val
                    },
                    action: {
                        viewModel.fiatSelectTapped()
                    }).cornerRadius(
                        radius: 12,
                        corners: [.topRight, .bottomRight]
                    )
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
            ScrollViewReader { scrollView in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.availableMethods, id: \.name) { item in
                            Button {
                                viewModel.didSelectPayment(item)
                                withAnimation {
                                    scrollView.scrollTo(item.type, anchor: .center)
                                }
                            } label: {
                                methodCard(item: item)
                                    .foregroundColor(Color(Asset.Colors.night.color))
                            }
                            .addBorder(
                                item.type == viewModel.selectedPayment ?
                                    Color(Asset.Colors.night.color) :
                                    Color.clear, width: 1, cornerRadius: 16
                            ).id(item.type)
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
            } else {
                Button { [weak viewModel] in
                    viewModel?.didTapTotal()
                } label: {
                    Text("\(viewModel.total) USD")
                        .apply(style: .text3)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
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
                if viewModel.selectedPayment == item.type {
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

    func inputView(text: Binding<String>, coin: String, onEditing: @escaping (Bool) -> Void, action: @escaping () -> Void) -> some View {
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


struct AutoFocusTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focus: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<AutoFocusTextField>) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: UITextField, context:
        UIViewRepresentableContext<AutoFocusTextField>) {
        uiView.text = text
//        if uiView.window != nil, !uiView.isFirstResponder && !focus {
////            uiView.becomeFirstResponder()
//            focus = true
//        } else {
//            focus = false
//        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoFocusTextField

        init(_ autoFocusTextField: AutoFocusTextField) {
            self.parent = autoFocusTextField
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
