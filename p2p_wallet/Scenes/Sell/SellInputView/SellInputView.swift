//
//  SellInputView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2022.
//

import SwiftUI
import KeyAppUI
import Combine

struct SellInputView: View {
    @ObservedObject var viewModel: SellInputViewModel
    
    init(viewModel: SellInputViewModel) {
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
                        Rectangle().frame(width: .infinity, height: 1)
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
                TextField("0", text: $viewModel.baseAmount)
                    .disableAutocorrection(true)
                
                Text("SOL")
                    .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
            }
                .font(uiFont: UIFont.font(of: .text3, weight: .regular))
                .blockStyle()
        }
        .padding(.top, 44)
    }
    
    var sellAllButton: some View {
        Button {
            // TODO: - Action
        } label: {
            HStack(spacing: 4) {
                Text("Sell all")
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: UIFont.font(of: .label1, weight: .regular))
                Text("4.53 SOL")
                    .foregroundColor(Color(Asset.Colors.sky.color))
                    .font(uiFont: UIFont.font(of: .label1, weight: .regular))
            }
        }
    }
    
    var quoteAmountInputView: some View {
        HStack {
            TextField("0", text: $viewModel.quoteAmount)
                .disableAutocorrection(true)
                
            Text("≈ EUR")
                .foregroundColor(Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
        }
        .font(uiFont: UIFont.font(of: .title1, weight: .bold))
        
    }
    
    var exchangeRateView: some View {
        HStack {
            Text("1 SOL ≈ 60.05 EUR")
            Spacer()
        }
            .descriptionTextStyle()
            .padding(4)
            .padding(.bottom, 12)
    }
    
    var feeView: some View {
        HStack {
            Text("Included fee 0.03 SOL")
            Spacer()
        }
            .descriptionTextStyle()
            .padding(4)
            .padding(.top, 12)
    }
    
    var sellButton: some View {
        TextButtonView(
            title: "Sell",
            style: .primaryWhite,
            size: .large
        ) { [weak viewModel] in
//            viewModel?.buyButtonTapped()
        }
        .frame(height: 56)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
        .disabled(false)
    }
}

private struct NumberTextField: View {
    @Binding private var number: String

    var body: some View {
        TextField("Total number of people", text: $number)
            .keyboardType(.numberPad)
    }
}

private extension View {
    func blockStyle() -> some View {
        frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(12)
            .padding(.horizontal, 16)
    }
    
    func descriptionTextStyle() -> some View {
        foregroundColor(Color(Asset.Colors.mountain.color))
            .font(uiFont: UIFont.font(of: .label1, weight: .regular))
    }
}

struct SellInputView_Previews: PreviewProvider {
    static var previews: some View {
        SellInputView(viewModel: .init())
    }
}
