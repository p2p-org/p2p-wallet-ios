//
//  SwapSettingsView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import Combine
import KeyAppUI
import SkeletonUI
import SwiftUI

struct SwapSettingsView: View {
    @ObservedObject var viewModel: SwapSettingsViewModel

    var body: some View {
        ColoredBackground {
            VStack(spacing: 4) {
                exchangeRate
                list
            }
        }
    }

    var exchangeRate: some View {
        Text(viewModel.info.exchangeRateInfo)
            .apply(style: .label1)
            .foregroundColor(Color(Asset.Colors.night.color))
            .accessibilityIdentifier("SwapView.priceInfoLabel")
            .if(viewModel.isLoading) { view in
                view.skeleton(with: true, size: CGSize(width: 160, height: 16))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 16)
    }

    var list: some View {
        List {
            Section {
                firstSectionRows
            }

            Section {
                commonRow(
                    title: L10n.minimumReceived,
                    subtitle: (
                        viewModel.info.minimumReceived ??
                            SwapTokenAmountInfo(amount: 0, token: "")
                    )
                    .amountDescription,
                    identifier: .minimumReceived
                )
            }

            Section(header: Text(L10n.slippage)) {
                SlippageSettingsView(slippage: viewModel.selectedSlippage) { selectedSlippage in
                    viewModel.selectedSlippage = selectedSlippage
                }
            }
        }
        .modifier(ListBackgroundModifier(separatorColor: Asset.Colors.rain.color))
        .listStyle(InsetGroupedListStyle())
        .scrollDismissesKeyboard()
    }

    // MARK: - First section

    private var firstSectionRows: some View {
        Group {
            // Route
            if viewModel.isLoadingOrRouteNotNil {
                routeView
            }

            // Network fee
            feeRow(
                title: L10n.networkFee,
                fee: viewModel.info.networkFee,
                identifier: .networkFee
            )

            // Account creation fee
            if viewModel.isLoadingOrRouteNotNil {
                feeRow(
                    title: L10n.accountCreationFee,
                    fee: viewModel.info.accountCreationFee,
                    identifier: .accountCreationFee
                )
            }

            // Liquidity fee
            if viewModel.isLoadingOrRouteNotNil {
                if !viewModel.info.liquidityFee.isEmpty {
                    feeRow(
                        title: L10n.liquidityFee,
                        fees: viewModel.info.liquidityFee,
                        identifier: .liquidityFee
                    )
                }
            }

            // Estimated fee
            if viewModel.isLoadingOrRouteNotNil, viewModel.info.estimatedFees != nil {
                HStack {
                    Text(L10n.estimatedFees)
                        .fontWeight(.semibold)
                        .apply(style: .text3)

                    Spacer()

                    Text(viewModel.info.estimatedFees)
                        .fontWeight(.semibold)
                        .apply(style: .text3)
                        .padding(.vertical, 10)
                        .skeleton(with: viewModel.isLoading, size: .init(width: 52, height: 16))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var routeView: some View {
        commonRow(
            title: L10n.swappingThrough,
            subtitle: viewModel.info.currentRoute?.tokensChain,
            trailingSubtitle: viewModel.info.currentRoute?.description,
            trailingView: Image(.nextArrow)
                .resizable()
                .frame(width: 7.41, height: 12)
                .padding(.vertical, (20 - 12) / 2)
                .padding(.horizontal, (20 - 7.41) / 2)
                .castToAnyView(),
            identifier: .route
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.rowClicked(identifier: .route)
        }
    }

    private func feeRow(
        title: String,
        fee: SwapFeeInfo?,
        identifier: RowIdentifier?
    ) -> some View {
        commonRow(
            title: title,
            subtitle: fee?.amountDescription,
            subtitleColor: fee?.shouldHighlightAmountDescription == true ? Asset.Colors.mint.color : Asset.Colors
                .mountain.color,
            trailingSubtitle: fee?.amountInFiatDescription,
            identifier: identifier
        )
    }

    private func feeRow(
        title: String,
        fees: [SwapFeeInfo],
        identifier: RowIdentifier?
    ) -> some View {
        let fiatAmount = fees.compactMap(\.amountInFiat).reduce(0.0, +)
        return commonRow(
            title: title,
            subtitle: fees.compactMap(\.amountDescription).joined(separator: ", "),
            trailingSubtitle: fiatAmount > 0 ? "≈ " + fiatAmount.fiatAmountFormattedString() : nil,
            identifier: identifier
        )
    }

    private func commonRow(
        title: String,
        subtitle: String?,
        subtitleColor: UIColor = Asset.Colors.mountain.color,
        trailingSubtitle: String? = nil,
        trailingView: AnyView = Image(.infoStraight)
            .resizable()
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .frame(width: 20, height: 20)
            .castToAnyView(),
        identifier: RowIdentifier?
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(subtitleColor))
                    .skeleton(with: viewModel.isLoading, size: .init(width: 100, height: 12))
            }

            Spacer()

            Text(trailingSubtitle)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .layoutPriority(1)
                .skeleton(with: viewModel.isLoading, size: .init(width: 52, height: 16))

            trailingView
                .onTapGesture {
                    guard let identifier else { return }
                    viewModel.rowClicked(identifier: identifier)
                }
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// struct SwapSettingsView_Previews: PreviewProvider {
//    static let viewModel = SwapSettingsViewModel(
//        status: .loading,
//        slippage: 0.5,
//        swapStatePublisher: PassthroughSubject<JupiterSwapState, Never>().eraseToAnyPublisher()
//    )
//    static var previews: some View {
//        SwapSettingsView(viewModel: viewModel)
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
//                let info = SwapSettingsViewModel.Info(
//                    routes: [
//                        .init(
//                            id: "1",
//                            name: "Raydium",
//                            description: "Best price",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        ),
//                        .init(
//                            name: "Raydium 95% + Orca 5%",
//                            description: "-0.0006 TokenB",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        ),
//                        .init(
//                            name: "Raydium 95% + Orca 5%",
//                            description: "-0.0006 TokenB",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        )
//                    ],
//                    currentRoute: .init(
//                        name: "Raydium",
//                        description: "Best price",
//                        tokensChain: "SOL→CLMM→USDC→CRAY"
//                    ),
//                    networkFee: .init(
//                        amount: 0,
//                        tokenSymbol: nil,
//                        tokenName: nil,
//                        tokenPriceInCurrentFiat: nil,
//                        pct: nil,
//                        canBePaidByKeyApp: true
//                    ),
//                    accountCreationFee: .init(
//                        amount: 0.8,
//                        tokenSymbol: "Token A",
//                        tokenName: "Token A Name",
//                        tokenPriceInCurrentFiat: 6.1 / 0.8,
//                        pct: nil,
//                        canBePaidByKeyApp: false
//                    ),
//                    liquidityFee: [
//                        .init(
//                            amount: 0.991,
//                            tokenSymbol: "Token C",
//                            tokenName: "Token C Name",
//                            tokenPriceInCurrentFiat: 0.05 / 0.991,
//                            pct: 0.01,
//                            canBePaidByKeyApp: false
//                        ),
//                        .init(
//                            amount: 0.991,
//                            tokenSymbol: "Token D",
//                            tokenName: "Token D Name",
//                            tokenPriceInCurrentFiat: 0.05 / 0.991,
//                            pct: 0.01,
//                            canBePaidByKeyApp: false
//                        )
//                    ],
//                    minimumReceived: .init(
//                        amount: 0.91,
//                        token: "TokenB"
//                    ),
//                    exchangeRateInfo: "1 SOL ≈ 12.85 USD"
//                )
//
//                viewModel.status = .loaded(
//                    info
//                )
//            }
//        }
//    }
// }

// MARK: - Row idenfifier

extension SwapSettingsView {
    enum RowIdentifier: Equatable {
        case route
        case networkFee
        case accountCreationFee
        case liquidityFee
        case minimumReceived
    }
}
