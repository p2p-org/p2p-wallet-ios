//
//  SlippageSettingsView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/03/2023.
//

import SwiftUI
import KeyAppUI

struct SlippageSettingsView: View {
    @StateObject private var viewModel: SlippageSettingsViewModel
    
    @State private var textFieldColor: UIColor = Asset.Colors.night.color
    
    let onSelectSlippage: (Double?) -> Void
    
    init(slippage: Double?, onSelectSlippage: @escaping (Double?) -> Void) {
        self._viewModel = StateObject(wrappedValue: .init(slippage: slippage))
        self.onSelectSlippage = onSelectSlippage
    }
    
    var body: some View {
        ForEach(Array(zip(viewModel.slippages.indices, viewModel.slippages)), id: \.0) { index, slippage in
            Button(
                action: {
                    viewModel.selectRow(at: index)
                },
                label: {
                    cell(index: index, slippage: slippage)
                }
            )
        }
        .onChange(of: viewModel.isCustomSlippageValid) { isSlippageValid in
            textFieldColor = isSlippageValid ? Asset.Colors.night.color : Asset.Colors.rose.color
        }
        .onChange(of: viewModel.selectedSlippage) { selectedSlippage in
            onSelectSlippage(selectedSlippage)
        }
    }
    
    @ViewBuilder
    func cell(index: Int, slippage: Double?) -> some View {
        if let slippage = slippage {
            staticSelectionCell(index: index, slippage: slippage)
        } else {
            customInput(index: index)
        }
    }
    
    @ViewBuilder
    func staticSelectionCell(index: Int, slippage: Double) -> some View {
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
    }
    
    @ViewBuilder
    func customInput(index: Int) -> some View {
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
                                        lineWidth: viewModel.isCustomSlippageValid ? 0 : 1
                                    )
                            )
                        
                        percentSuffixTextField
                        
                    }
                    Text("\(L10n.theSlippageCouldBe) 0.01-50%")
                        .foregroundColor(viewModel.isCustomSlippageValid ? Color(Asset.Colors.mountain.color): Color(Asset.Colors.rose.color))
                        .font(uiFont: .font(of: .label1))
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    var percentSuffixTextField: some View {
        HStack(alignment: .center, spacing: 4) {
            DecimalTextField(
                value: $viewModel.customSlippage,
                isFirstResponder: $viewModel.isCustomSlippageSelected,
                textColor: $textFieldColor
            ) { textField in
                textField.font = .font(of: .text3)
                textField.keyboardType = .decimalPad
                textField.placeholder = "0"
                textField.maximumFractionDigits = 2
                textField.decimalSeparator = "."
                textField.setContentHuggingPriority(.required, for: .horizontal)
            }
            
            Text("%")
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))

            Spacer(minLength: 0)
        }
            .onTapGesture {
                viewModel.isCustomSlippageSelected.toggle()
            }
            .padding(.horizontal, 16)
    }
}

struct SlippageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                SlippageSettingsView(slippage: 0.5) {_ in }
            }
        }
    }
}
