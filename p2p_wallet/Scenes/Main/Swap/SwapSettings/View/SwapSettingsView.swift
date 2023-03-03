//
//  SwapSettingsView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import SwiftUI
import KeyAppUI

struct SwapSettingsView: View {
    @ObservedObject var viewModel: SwapSettingsViewModel
    
    @State private var failureSlippage: Bool = false
    @State private var textFieldColor: UIColor = Asset.Colors.night.color
    
    var body: some View {
        List {
            Section {
                fisrtSectionRows
            }
            Section {
                commonRow(
                    title: L10n.minimumReceived,
                    subtitle: viewModel.minimumReceived?.amountDescription,
                    activeInfoRow: .minimumReceived
                )
                .padding(.vertical, 14)
            }
            Section(header: Text(L10n.slippage)) {
                slippageRows
            }
        }
    }
    
    // MARK: - First section

    private var fisrtSectionRows: some View {
        Group {
            // Route
            commonRow(
                title: L10n.swappingThrough,
                subtitle: viewModel.currentRoute.tokensChain,
                activeInfoRow: .route,
                trailingSubtitle: viewModel.currentRoute.description,
                trailingView: Image(uiImage: .nextArrow)
                    .resizable()
                    .frame(width: 7.41, height: 12)
                    .padding(.vertical, (20-12)/2)
                    .padding(.horizontal, (20-7.41)/2)
                    .castToAnyView()
            )
            .padding(.vertical, 14)
            
            // Network fee
            feeRow(
                title: L10n.networkFee,
                fee: viewModel.networkFee,
                canBePaidByKeyApp: true,
                activeInfoRow: .networkFee
            )
            .padding(.vertical, 14)
            
            // Account creation fee
            feeRow(
                title: L10n.accountCreationFee,
                fee: viewModel.accountCreationFee,
                canBePaidByKeyApp: false,
                activeInfoRow: .accountCreationFee
            )
            .padding(.vertical, 14)
            
            // Liquidity fee
            feeRow(
                title: L10n.liquidityFee,
                fees: viewModel.liquidityFee
            )
            .padding(.vertical, 14)
            
            // Estimated fee
            HStack {
                Text(L10n.estimatedFees)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                
                Spacer()
                
                Text(viewModel.estimatedFees)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
    
    private func feeRow(
        title: String,
        fee: SwapSettingsFeeInfo?,
        canBePaidByKeyApp: Bool,
        activeInfoRow: ActiveInfoRow?
    ) -> some View {
        commonRow(
            title: title,
            subtitle: fee?.amountDescription,
            activeInfoRow: activeInfoRow,
            subtitleColor: fee?.shouldHighlightAmountDescription == true ? Asset.Colors.mint.color: Asset.Colors.mountain.color,
            trailingSubtitle: fee?.amountInFiatDescription
        )
    }
    
    private func feeRow(
        title: String,
        fees: [SwapSettingsFeeInfo]
    ) -> some View {
        commonRow(
            title: title,
            subtitle: fees.compactMap(\.amountDescription).joined(separator: ", "),
            activeInfoRow: .liquidityFee,
            trailingSubtitle: "≈ " + fees.compactMap(\.amountInFiat).reduce(0.0, +).fiatAmountFormattedString()
        )
    }
    
    private func commonRow(
        title: String,
        subtitle: String?,
        activeInfoRow: ActiveInfoRow?,
        subtitleColor: UIColor = Asset.Colors.mountain.color,
        trailingSubtitle: String? = nil,
        trailingView: AnyView = Image(uiImage: .infoStraight)
            .resizable()
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .frame(width: 20, height: 20)
            .castToAnyView()
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                if subtitle?.isEmpty == false {
                    Text(subtitle)
                        .apply(style: .label1)
                        .foregroundColor(Color(subtitleColor))
                }
            }
            
            Spacer()
            
            Text(trailingSubtitle)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .layoutPriority(1)
                .padding(.trailing, 10)
            
            trailingView
                .onTapGesture {
                    guard let activeInfoRow = activeInfoRow else { return }
                    viewModel.rowClicked(type: activeInfoRow)
                }
        }
    }
    
    // MARK: - Slippage section

    private var slippageRows: some View {
        ForEach(Array(zip(viewModel.slippages.indices, viewModel.slippages)), id: \.0) { index, slippage in
            Button(
                action: {
                    viewModel.selectedIndex = index
                },
                label: {
                    if let slippage = slippage {
                        HStack {
                            Text("\(String(format: "%.1f", slippage))%")
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text3))
                            Spacer()
                            if index == viewModel.selectedIndex {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(.vertical, 16)
                    } else {
                        VStack {
                            HStack {
                                Text(L10n.custom)
                                    .foregroundColor(Color(Asset.Colors.night.color))
                                    .font(uiFont: .font(of: .text3))
                                Spacer()
                                if index == viewModel.selectedIndex {
                                    Image(systemName: "checkmark")
                                }
                            }
                            if index == viewModel.selectedIndex {
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack {
                                        Color(Asset.Colors.rain.color)
                                            .frame(height: 44)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        Color(Asset.Colors.rose.color),
                                                        lineWidth: failureSlippage ? 1 : 0
                                                    )
                                            )
                                        TextFieldWithSuffix(
                                            title: nil,
                                            text: $viewModel.slippage,
                                            textColor: $textFieldColor,
                                            becomeFirstResponder: $viewModel.customSelected
                                        )
                                        .padding(.horizontal, 16)
                                    }
                                    Text("\(L10n.theSlippageCouldBe) 0.01-50%")
                                        .foregroundColor(failureSlippage ? Color(Asset.Colors.rose.color) : Color(Asset.Colors.mountain.color))
                                        .font(uiFont: .font(of: .label1))
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            )
        }
        .onChange(of: viewModel.failureSlippage) { failureSlippage in
            textFieldColor = !failureSlippage ? Asset.Colors.night.color : Asset.Colors.rose.color
            self.failureSlippage = failureSlippage
        }
    }
}

// MARK: - ActiveInfoRow

extension SwapSettingsView {
    enum ActiveInfoRow {
        case route
        case networkFee
        case accountCreationFee
        case liquidityFee
        case minimumReceived
    }
}
