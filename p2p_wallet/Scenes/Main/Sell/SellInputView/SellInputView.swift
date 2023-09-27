import AnalyticsManager
import Combine
import Resolver
import SkeletonUI
import SwiftUI

struct SellInputView: View {
    @Injected private var analyticsManager: AnalyticsManager

    @ObservedObject var viewModel: SellViewModel

    init(viewModel: SellViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            exchangeRateView
                .padding(.top, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    baseAmountInputView

                    feeView
                }
                .frame(maxWidth: .infinity)
            }.scrollDismissesKeyboard()
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    UIApplication.shared.keyWindow?.endEditing(true)
                }
            Spacer()
            if !viewModel.isEnteringBaseAmount, !viewModel.isEnteringQuoteAmount {
                poweredBy
                    .padding(.bottom, 37)
            }
            sellButton
        }
        .frame(maxWidth: .infinity)
        .background(Color(.smoke))
        .onAppear {
            analyticsManager.log(event: .sellAmount)
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
                    .foregroundColor(Color(.night))

                Spacer()

                if viewModel.showingBaseAmount {
                    textField(value: $viewModel.baseAmount, isFirstResponder: $viewModel.isEnteringBaseAmount)
                } else {
                    textField(value: $viewModel.quoteAmount, isFirstResponder: $viewModel.isEnteringQuoteAmount)
                }
            }

            HStack {
                Text(L10n.cashOutReceive(viewModel.baseCurrencyCode, viewModel.quoteCurrencyCode))
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))

                Spacer()
                Text("≈ " + viewModel.quoteReceiveAmount.toString() + " " + viewModel.quoteCurrencyCode)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
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
                L10n.switchTo(viewModel.showingBaseAmount ? viewModel.quoteCurrencyCode : viewModel.baseCurrencyCode)
            )
            .apply(style: .label1)
            .foregroundColor(Color(.sky))
        }
    }

    var sellAllButton: some View {
        Button {
            viewModel.sellAll()
        } label: {
            HStack(spacing: 4) {
                Text(L10n.all)
                    .apply(style: .label1)
                    .foregroundColor(Color(.mountain))
                Text(
                    (viewModel.maxBaseAmount ?? 0).toString(maximumFractionDigits: 2, roundingMode: .down) +
                        " \(viewModel.baseCurrencyCode)"
                )
                .apply(style: .label1)
                .foregroundColor(Color(.sky))
            }
        }
    }

    var poweredBy: some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 4) {
                Text(L10n.poweredBy + " Moonpay")
                    .apply(style: .label1)
                    .foregroundColor(Color(.h9799Af))
                Button {
                    viewModel.moonpayLicenseTap()
                } label: {
                    Text(L10n.license)
                        .apply(style: .label1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.night))
                }
            }
            Spacer()
        }
    }

    var exchangeRateView: some View {
        HStack {
            Spacer()
            switch viewModel.exchangeRate {
            case .loading:
                Text("1 SOL ≈ 12.05 USD")
                    .skeleton(
                        with: true,
                        size: CGSize(width: 107, height: 16),
                        animated: .default
                    )
            case let .loaded(exchangeRate):
                Text(
                    "1 \(viewModel.baseCurrencyCode) ≈ \(exchangeRate.toString(maximumFractionDigits: 2)) \(viewModel.quoteCurrencyCode)"
                )
                .descriptionTextStyle(color: Color(.night))
            case let .error(error):
                #if !RELEASE
                    Text("\(L10n.errorWhenUpdatingPrices): \(error.localizedDescription)")
                        .descriptionTextStyle(color: Color(.rose))
                #else
                    Text(L10n.errorWhenUpdatingPrices)
                        .descriptionTextStyle(color: Color(.rose))
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
            case let .loaded(fee):
                Text(L10n.allFeesIncluded(
                    fee.baseAmount.toString(maximumFractionDigits: 2),
                    viewModel.baseCurrencyCode,
                    fee.quoteAmount.toString(),
                    viewModel.quoteCurrencyCode
                ))
                .apply(style: .label1)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.night))
            case let .error(error):
                #if !RELEASE
                    Text("\(L10n.errorWhenUpdatingPrices): \(error.localizedDescription)")
                        .apply(style: .label1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.rose))
                #else
                    Text(L10n.errorWhenUpdatingPrices)
                        .apply(style: .label1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.rose))
                #endif
            }
            Spacer()
        }
        .padding(4)
        .padding(.top, 12)
    }

    var sellButton: some View {
        TextButtonView(
            title: viewModel.inputError != nil ? viewModel.inputError!.recomendation : L10n.cashOut,
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

    func textField(value: Binding<Double?>, isFirstResponder: Binding<Bool>) -> DecimalTextField {
        DecimalTextField(
            value: value,
            isFirstResponder: isFirstResponder,
            textColor: .constant(.init(resource: .night))
        ) { textField in
            textField.font = .font(of: .largeTitle, weight: .regular)
            textField.keyboardType = .decimalPad
            textField.maximumFractionDigits = 2
            textField.decimalSeparator = "."
            textField.textAlignment = .right
        }
    }
}

private extension View {
    func blockStyle(hasError: Bool = false) -> some View {
        frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(.snow))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.rose), lineWidth: hasError ? 1 : 0)
            )
            .padding(.horizontal, 16)
    }

    func descriptionTextStyle(color: Color = Color(.mountain)) -> some View {
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
            ))
    }
}
