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
            Section(header: Text(L10n.slippage)) {
                slippageRows
            }
        }
    }
    
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
