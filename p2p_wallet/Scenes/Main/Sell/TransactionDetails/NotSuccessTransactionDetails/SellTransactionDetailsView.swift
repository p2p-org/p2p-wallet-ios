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
        VStack(spacing: 44) {
            VStack(spacing: 16) {
                SellTransactionDetailsTopView(model: viewModel.topViewModel)
                descriptionBlockView
                    .padding(.horizontal, 24)
            }
            buttonsView
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
            infoBlockView
            if viewModel.strategy != .youVeNotSent {
                textView
            }
        }
    }

    private var infoBlockView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(uiImage: .sellInfo)
                .renderingMode(.template)
                .foregroundColor(infoIconColor)
            switch viewModel.infoText {
            case let .raw(text):
                Text(text)
                    .foregroundColor(infoBlockTextColor)
                    .apply(style: .text3)
            case let .help(text):
                Text(text)
                    .onTapGesture(perform: viewModel.helpTapped)
            }
        }
        .padding(12)
        .background(infoBlockBackgroundColor)
        .cornerRadius(12)
    }

    private var infoIconColor: Color {
        switch viewModel.strategy {
        case .processing, .fundsWereSent:
            return Color(UIColor._9799Af)
        case .youNeedToSend:
            return Color(Asset.Colors.sun.color)
        case .youVeNotSent:
            return Color(Asset.Colors.rose.color)
        }
    }

    private var infoBlockTextColor: Color {
        switch viewModel.strategy {
        case .processing, .fundsWereSent, .youNeedToSend:
            return Color(Asset.Colors.night.color)
        case .youVeNotSent:
            return Color(Asset.Colors.rose.color)
        }
    }

    private var infoBlockBackgroundColor: Color {
        switch viewModel.strategy {
        case .processing, .fundsWereSent, .youNeedToSend:
            return Color(UIColor.e0E0E7)
        case .youVeNotSent:
            return Color(Asset.Colors.rose.color).opacity(0.1)
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

// MARK: - View Height

extension SellTransactionDetailsView {
    var viewHeight: CGFloat {
        switch viewModel.strategy {
        case .processing:
            return 640
        case .fundsWereSent:
            return 718
        case .youNeedToSend:
            return 694
        case .youVeNotSent:
            return 682
        }
    }
}
