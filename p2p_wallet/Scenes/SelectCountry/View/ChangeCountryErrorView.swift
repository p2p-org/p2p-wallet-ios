//
//  ChangeCountryErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 12.04.2023.
//

import SwiftUI
import KeyAppUI

struct ChangeCountryErrorView: View {
    
    let model: ChangeCountryModel
    let buttonAction: () -> Void
    let subButtonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(uiImage: model.image)
            VStack(spacing: 8) {
                Text(model.title)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title1, weight: .bold))
                Text(model.subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text1))
            }
            Spacer()
            actions
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
    
    private var actions: some View {
        VStack(spacing: 12) {
            Button(
                action: {
                    buttonAction()
                },
                label: {
                    Text(model.buttonTitle)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                }
            )
            Button(
                action: {
                    subButtonAction()
                },
                label: {
                    Text(model.subButtonTitle)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                }
            )
        }
    }
}

// MARK: - Model

extension ChangeCountryErrorView {
    struct ChangeCountryModel {
        let image: UIImage
        let title: String
        let subtitle: String
        let buttonTitle: String
        let subButtonTitle: String
    }
}
