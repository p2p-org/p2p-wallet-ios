import SwiftUI
import KeyAppUI
import Combine

struct SellInputView: View {
    @ObservedObject var viewModel: SellViewModel

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    init(viewModel: SellViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    baseAmountInputView

                    quoteAmountInputView
                        .blockStyle()

                    VStack(alignment: .leading, spacing: 0) {
                        exchangeRateView
                        Rectangle().frame(height: 1)
                            .foregroundColor(Color(Asset.Colors.smoke.color))
                        feeView
                    }
                    .blockStyle()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }
//            .onTapGesture {
//                UIApplication.shared.keyWindow?.endEditing(true)
//            }
            Spacer()
            sellButton
        }
        .frame(maxWidth: .infinity)
        .background(Color(Asset.Colors.smoke.color))
    }

    // MARK: - Subviews

    var baseAmountInputView: some View {
        VStack(alignment: .leading, spacing: 4) {
            sellAllButton
                .padding(.leading, 24)

            HStack {
                DecimalTextField(
                     value: $viewModel.baseAmount,
                     isFirstResponder: $viewModel.isEnteringBaseAmount
                 ) { textField in
                     textField.font = UIFont.font(of: .text3, weight: .regular)
                     textField.keyboardType = .decimalPad
                     textField.maximumFractionDigits = 2
                 }

                 Text(viewModel.baseCurrencyCode)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color).opacity(0.3))
            }
                .blockStyle(hasError: viewModel.errorText != nil)
        }
        .padding(.top, 44)
    }

    var sellAllButton: some View {
        Button {
            viewModel.sellAll()
        } label: {
            HStack(spacing: 4) {
                Text(L10n.sellAll)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: UIFont.font(of: .label1, weight: .regular))
                Text((viewModel.maxBaseAmount ?? 0)
                    .toString(maximumFractionDigits: 2) + " \(viewModel.baseCurrencyCode)")
                    .foregroundColor(Color(Asset.Colors.sky.color))
                    .font(uiFont: UIFont.font(of: .label1, weight: .regular))
            }
        }
    }

    var quoteAmountInputView: some View {
        HStack {
            DecimalTextField(
                value: $viewModel.quoteAmount,
                isFirstResponder: $viewModel.isEnteringQuoteAmount
            ) { textField in
                textField.font = UIFont.font(of: .title1, weight: .bold)
                textField.keyboardType = .decimalPad
                textField.maximumFractionDigits = 2
            }

            Text("≈ \(viewModel.quoteCurrencyCode)")
                .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                .font(uiFont: UIFont.font(of: .title1, weight: .bold))
        }
        .font(uiFont: UIFont.font(of: .title1, weight: .bold))
    }

    var exchangeRateView: some View {
        HStack {
            Text("1 \(viewModel.baseCurrencyCode) ≈ \(viewModel.exchangeRate.toString()) \(viewModel.quoteCurrencyCode)")
            Spacer()
        }
            .descriptionTextStyle()
            .padding(4)
            .padding(.bottom, 12)
    }

    var feeView: some View {
        HStack {
            Text(L10n.includedFee("\(viewModel.fee) \(viewModel.quoteCurrencyCode)"))
            Spacer()
        }
            .descriptionTextStyle()
            .padding(4)
            .padding(.top, 12)
    }

    var sellButton: some View {
        TextButtonView(
            title:  viewModel.errorText != nil ? viewModel.errorText! : L10n.sell((viewModel.baseAmount ?? 0).toString() + " \(viewModel.baseCurrencyCode)"),
            style: .primaryWhite,
            size: .large
        ) { [weak viewModel] in
            viewModel?.sell()
        }
        .disabled(viewModel.errorText != nil)
        .frame(height: 56)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
    }
}

private extension View {
    func blockStyle(hasError: Bool = false) -> some View {
        frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(Asset.Colors.rose.color), lineWidth: hasError ? 1 : 0)
            )
            .padding(.horizontal, 16)
    }

    func descriptionTextStyle() -> some View {
        foregroundColor(Color(Asset.Colors.mountain.color))
            .font(uiFont: UIFont.font(of: .label1, weight: .regular))
    }
}

//
//struct SellInputView_Previews: PreviewProvider {
//    static var previews: some View {
//        SellInputView(viewModel: .init())
//    }
//}
