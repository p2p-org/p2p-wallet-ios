import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

/// Base Select View
struct BuySelect<Content: View>: View {
    let child: Content
    let didDismiss: (() -> Void)?
    let title: String

    init(
        title: String,
        didDismiss: (() -> Void)? = nil,
        @ViewBuilder child: () -> Content
    ) {
        self.child = child()
        self.didDismiss = didDismiss
        self.title = title
    }

    var body: some View {
        VStack {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)

            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.top, 11)

            Spacer()

            VStack {
                child.padding(.top, 21)
                Spacer()
                Button(
                    action: {
                        didDismiss?()
                    },
                    label: {
                        Text(L10n.done)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text2, weight: .bold))
                            .frame(height: 58)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.rain.color))
                            .padding(.horizontal, 2)
                            .cornerRadius(12)
                            .padding(.bottom, 16)
                    }
                )
            }.padding(.horizontal, 24)
        }
    }
}

protocol BuySelectViewModelCell: View {
    associatedtype Model: Hashable
    init(with: Model)
}

struct BuySelectView<Model, Cell: BuySelectViewModelCell>:
View where Model == Cell.Model {
    @ObservedObject var viewModel: BuySelectViewModel<Model>
    let title: String

    init(viewModel: BuySelectViewModel<Model>, title: String) {
        self.viewModel = viewModel
        self.title = title
    }

    var body: some View {
        BuySelect(title: title, didDismiss: {
            viewModel.coordinatorIO.didDissmiss.send()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.items, id: \.self) { model in
                    VStack {
                        HStack {
                            Button {
                                viewModel.didTapOn(model: model)
                            } label: {
                                modelCell(model: model)
                            }
                            Spacer()
                            if viewModel.selectedModel == model {
                                Image(uiImage: UIImage.checkBoxIOS)
                                    .frame(width: 15, height: 44)
                                    .padding(.trailing, 8)
                            }
                        }
                        if model != viewModel.items.last {
                            Divider()
                                .frame(height: 1)
                                .foregroundColor(Color(Asset.Colors.rain.color))
                        }
                    }
                }
            }.padding(.top, 10)
        }
    }

    // MARK: -

    private func modelCell(model: Cell.Model) -> some View {
        Cell(with: model)
    }
}

struct BuySelectTokenCellView: BuySelectViewModelCell {
    typealias Model = TokenCellViewItem

    let model: Model
    init(with: Model) {
        model = with
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(size: 48, args: .token(model.token))
                .frame(width: 48, height: 48)
                .cornerRadius(16)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.token.name)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.night.color))
                if let amount = model.amount {
                    Text(
                        amount.fiatAmountFormattedString(
                            maximumFractionDigits: 2,
                            currency: model.fiat ?? Fiat.usd
                        )
                    )
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 6)
        .frame(height: 67)
    }
}

struct FiatCellView: BuySelectViewModelCell {
    typealias Model = Fiat

    let model: Model
    init(with: Model) {
        model = with
    }

    var body: some View {
        HStack {
            Text(model.code)
                .apply(style: .text2)
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.leading)
                .padding(.leading, 5)
                .padding(.vertical, 3)
                .frame(height: 52)
            Spacer()
        }
    }
}
