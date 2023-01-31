//
//  SellTransactionDetailsView.swift
//  p2p_wallet
//
//  Created by Ivan on 15.12.2022.
//

import Combine
import SwiftUI
import KeyAppUI

struct SellTransactionDetailsView: View {
    let viewModel: SellTransactionDetailsViewModel

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 16) {
                SellTransactionDetailsTopView(model: viewModel.topViewModel)
                descriptionBlockView
                    .padding(.horizontal, 24)
            }
            Spacer()
                .frame(minHeight: 24, maxHeight: 44)
            buttonsView
            Spacer()
        }
        .padding(.bottom, 16)
        .sheetHeader(
            title: viewModel.title,
            withSeparator: false,
            bottomPadding: 4
        )
    }

    private var descriptionBlockView: some View {
        VStack(spacing: 52) {
            SellTransactionDetailsInfoView(
                viewModel: viewModel.infoModel,
                helpAction: viewModel.helpTapped
            )
            if viewModel.strategy != .youVeNotSent {
                textView
            }
        }
    }

    private var textView: some View {
        HStack {
            Text(viewModel.sendInfo?.0 ?? "")
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text4))
            Spacer()
            HStack(spacing: 8) {
                Text(viewModel.sendInfo?.1 ?? "")
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4, weight: .semibold))
                if viewModel.strategy.isYouNeedToSend {
                    Image(uiImage: .copyReceiverAddress)
                }
            }
            .onTapGesture {
                if viewModel.strategy.isYouNeedToSend {
                    viewModel.addressCopied()
                }
            }
        }
    }

    private var buttonsView: some View {
        VStack(spacing: 12) {
            topButton
            if !viewModel.isProcessing {
                bottomButton
            }
        }
    }

    private var topButton: some View {
        Button(
            action: {
                viewModel.topButtonClicked()
            },
            label: {
                Text(viewModel.topButtonTitle)
                    .foregroundColor(Color(viewModel.isProcessing ? Asset.Colors.night.color : Asset.Colors.snow.color))
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(Color(viewModel.isProcessing ? Asset.Colors.rain.color : Asset.Colors.night.color))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
        )
    }

    private var bottomButton: some View {
        Button(
            action: {
                viewModel.bottomButtonClicked()
            },
            label: {
                Text(viewModel.bottomButtonTitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text2, weight: .semibold))
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
            }
        )
    }
}
