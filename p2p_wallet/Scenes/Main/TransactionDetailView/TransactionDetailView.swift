//
//  DetailTransactionView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import KeyAppUI
import Resolver
import SwiftUI

struct DetailTransactionView: View {
    @ObservedObject var viewModel: TransactionDetailViewModel
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
                
            title
                .padding(.top, 16)
                .padding(.bottom, 20)
            headerView
            info
                .padding(.top, 9)
                .padding(.horizontal, 18)
            status
            button
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
        .navigationBarHidden(true)
    }
    
    private var title: some View {
        VStack(spacing: 4) {
            Text(viewModel.rendableTransaction.title)
                .fontWeight(.bold)
                .apply(style: .title3)
                .foregroundColor(Color(Asset.Colors.night.color))
            if !viewModel.rendableTransaction.subtitle.isEmpty {
                Text(viewModel.rendableTransaction.subtitle)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }
    
    private var amountInFiatColor: Color {
        if case .error = viewModel.rendableTransaction.status {
            return Color(Asset.Colors.rose.color)
        }
        
        switch viewModel.rendableTransaction.amountInFiat {
        case .positive:
            return Color(Asset.Colors.mint.color)
        default:
            return Color(Asset.Colors.night.color)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 0) {
            TransactionDetailIconView(icon: viewModel.rendableTransaction.icon)
                .padding(.top, 33)
            if !viewModel.rendableTransaction.amountInFiat.value.isEmpty {
                Text(viewModel.rendableTransaction.amountInFiat.value)
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                    .foregroundColor(amountInFiatColor)
                    .padding(.top, 17)
                    .padding(.bottom, 6)
            }
            if !viewModel.rendableTransaction.amountInToken.isEmpty {
                Text(viewModel.rendableTransaction.amountInToken)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.top, viewModel.rendableTransaction.amountInFiat.value.isEmpty ? 16 : 0)
            }
            
            if !viewModel.rendableTransaction.actions.isEmpty {
                HStack(spacing: 32) {
                    ForEach(viewModel.rendableTransaction.actions) { action in
                        switch action {
                        case .share:
                            CircleButton(title: L10n.share, image: .share1) {
                                viewModel.share()
                            }
                        case .explorer:
                            CircleButton(title: L10n.explorer, image: .explorer) {
                                viewModel.explore()
                            }
                        }
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 32)
            } else {
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .padding(.bottom, 34)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(Asset.Colors.smoke.color))
    }
    
    var info: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.rendableTransaction.extra, id: \.title) { infoItem in
                HStack {
                    Text(infoItem.title)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Spacer()
                    Button {
                        let clipboardManager: ClipboardManager = Resolver.resolve()
                        clipboardManager.copyToClipboard(infoItem.copyableValue ?? "")
                        
                        let notification: NotificationService = Resolver.resolve()
                        notification.showInAppNotification(.done(L10n.theAddressWasCopiedToClipboard))
                    } label: {
                        Text(infoItem.value)
                            .fontWeight(.bold)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
                        if infoItem.copyableValue != nil {
                            Image(uiImage: .copyReceiverAddress)
                        }
                    }.allowsHitTesting(infoItem.copyableValue != nil)
                }
                .frame(minHeight: 40)
            }
        }
    }

    var status: some View {
        if
            case let .succeed(message) = viewModel.rendableTransaction.status,
            message.isEmpty
        {
            return AnyView(
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .padding(.bottom, 12)
            )
        } else {
            return AnyView(
                TransactionDetailStatusView(
                    status: viewModel.rendableTransaction.status,
                    context: viewModel.statusContext
                ) {}
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            )
        }
    }

    var button: some View {
        var style: TextButton.Style {
            switch viewModel.style {
            case .active:
                return .primaryWhite
            case .passive:
                return .second
            }
        }
        
        return TextButtonView(
            title: viewModel.closeButtonTitle,
            style: style,
            size: .large,
            onPressed: { viewModel.action.send(.close) }
        )
        .frame(height: 56)
    }
}

struct DetailTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        DetailTransactionView(
            viewModel: .init(
                rendableDetailTransaction: MockedRendableDetailTransaction.send(),
                style: .passive
            )
        )
    }
}
