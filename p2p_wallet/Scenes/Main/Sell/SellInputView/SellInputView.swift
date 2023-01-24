import AnalyticsManager
import SwiftUI
import KeyAppUI
import Combine
import Resolver
import SkeletonUI

struct SellInputView: View {
    @Injected private var analyticsMAnager: AnalyticsManager

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
            exchangeRateView
                .padding(.horizontal, 16)
                .padding(.top, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    baseAmountInputView

                    feeView
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
        .onAppear {
            analyticsMAnager.log(event: AmplitudeEvent.sellAmount)
        }
    }

    // MARK: - Subviews

    var baseAmountInputView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                switchButton
                Spacer()
                sellAllButton
            }

            HStack {
                Text(viewModel.currentInputTypeCode)
                   .apply(style: .largeTitle)
                   .foregroundColor(Color(Asset.Colors.night.color))

                Spacer()

                if viewModel.showingBaseAmount {
                    DecimalTextField(
                        value: $viewModel.baseAmount,
                        isFirstResponder: $viewModel.isEnteringBaseAmount
                    ) { textField in
                        textField.font = UIFont.font(of: .largeTitle, weight: .regular)
                        textField.keyboardType = .decimalPad
                        textField.maximumFractionDigits = 2
                        textField.decimalSeparator = "."
                        textField.textAlignment = .right
                    }
                } else {
                    DecimalTextField(
                         value: $viewModel.quoteAmount,
                         isFirstResponder: $viewModel.isEnteringQuoteAmount
                     ) { textField in
                         textField.font = UIFont.font(of: .largeTitle, weight: .regular)
                         textField.keyboardType = .decimalPad
                         textField.maximumFractionDigits = 2
                         textField.decimalSeparator = "."
                         textField.textAlignment = .right
                     }
                }
            }

            HStack {
                Text("Cash out SOL, receive \(viewModel.quoteCurrencyCode)")
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))

                Spacer()
                Text("≈ " + viewModel.quoteAmount?.toString() + "")
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
        .blockStyle()
        .padding(.top, 44)
    }

    var switchButton: some View {
        Button(action: {
            viewModel.showingBaseAmount.toggle()
        }) {
            Text(
                "Switch to " + (viewModel.showingBaseAmount ? viewModel.quoteCurrencyCode : viewModel.baseCurrencyCode)
            )
            .apply(style: .label1)
            .foregroundColor(Color(Asset.Colors.sky.color))
        }
    }

    var sellAllButton: some View {
        Button {
            viewModel.sellAll()
        } label: {
            HStack(spacing: 4) {
                Text(L10n.all)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Text(
                    (viewModel.maxBaseAmount ?? 0).toString(maximumFractionDigits: 2, roundingMode: .down) +
                    " \(viewModel.baseCurrencyCode)"
                )
                .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.sky.color))
            }
        }
    }

    var exchangeRateView: some View {
        HStack {
            switch viewModel.exchangeRate {
            case .loading:
                Text("1 SOL ≈ 12.05 USD")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 107, height: 16),
                        animated: .default
                    )
            case .loaded(let exchangeRate):
                Text("1 \(viewModel.baseCurrencyCode) ≈ \(exchangeRate.toString(maximumFractionDigits: 2)) \(viewModel.quoteCurrencyCode)")
                    .descriptionTextStyle(color: Color(Asset.Colors.night.color))
            case .error(let error):
                #if !RELEASE
                Text("\(L10n.errorWhenUpdatingPrices): \(error.localizedDescription)")
                    .descriptionTextStyle(color: Color(Asset.Colors.rose.color))
                #else
                Text(L10n.errorWhenUpdatingPrices)
                    .descriptionTextStyle(color: Color(Asset.Colors.rose.color))
                #endif
            }
            Spacer()
        }
            .padding(.bottom, 9)
    }

    var feeView: some View {
        HStack {
            Spacer()
            switch viewModel.fee {
            case .loading:
                Text("All fees included 0.03 SOL")
                    .multilineTextAlignment(.center)
                    .descriptionTextStyle()
                    .skeleton(
                        with: true,
                        size: CGSize(width: 126, height: 16),
                        animated: .default
                    )
            case .loaded(let fee):
                Text("All fees included \(fee.baseAmount.toString(maximumFractionDigits: 2)) \(viewModel.baseCurrencyCode) ≈ \(fee.quoteAmount.toString()) \(viewModel.quoteCurrencyCode)")
                    .apply(style: .label1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(Asset.Colors.night.color))
            case .error(let error):
                #if !RELEASE
                Text("\(L10n.errorWhenUpdatingPrices): \(error.localizedDescription)")
                    .apply(style: .label1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(Asset.Colors.rose.color))
                #else
                Text(L10n.errorWhenUpdatingPrices)
                    .apply(style: .label1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(Asset.Colors.rose.color))
                #endif
            }
            Spacer()
        }
            .padding(4)
            .padding(.top, 12)
    }

    var sellButton: some View {
        TextButtonView(
            title:  viewModel.inputError != nil ? viewModel.inputError!.recomendation : L10n.cashOut,
            style: .primaryWhite,
            size: .large
        ) { [weak viewModel] in
            UIApplication.shared.keyWindow?.endEditing(true)
            viewModel?.sell()
        }
        .disabled(viewModel.inputError != nil)
        .frame(height: 56)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
    }
}

private extension View {
    func blockStyle(hasError: Bool = false) -> some View {
        frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(Asset.Colors.rose.color), lineWidth: hasError ? 1 : 0)
            )
            .padding(.horizontal, 16)
    }

    func descriptionTextStyle(color: Color = Color(Asset.Colors.mountain.color)) -> some View {
        foregroundColor(color)
            .font(uiFont: UIFont.font(of: .label1, weight: .regular))
    }
}


struct SellInputView_Previews: PreviewProvider {
    static var previews: some View {
        SellInputView(viewModel:
                .init(
                    initialBaseAmount: 2,
                    navigation: PassthroughSubject<SellNavigation?, Never>()
                )
        )
    }
}
