//
//  DetailTransactionView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.02.2023.
//

import SwiftUI
import KeyAppUI

struct DetailTransactionView: View {
    @ObservedObject var viewModel: DetailTransactionViewModel
    
    var body: some View {
        VStack {
            title
                .padding(.top, 16)
                .padding(.bottom, 20)
            headerView
            info
                .padding(.top, 9)
                .padding(.horizontal, 18)
            status
                .padding(.horizontal, 16)
            Spacer()
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
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 0) {
            TransactionDetailIconView(icon: viewModel.rendableTransaction.icon)
                .padding(.top, 33)
            Text(viewModel.rendableTransaction.amountInFiat)
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 17)
                .padding(.bottom, 6)
            if !viewModel.rendableTransaction.amountInToken.isEmpty {
                Text(viewModel.rendableTransaction.amountInToken)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
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
                    Text(infoItem.value)
                        .fontWeight(.bold)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(minHeight: 40)
            }
        }
    }

    var status: some View {
        SwiftUI.EmptyView()
    }
//        SendTransactionStatusStatusView(
//            viewModel: viewModel,
//            errorMessageTapAction: { [weak viewModel] in viewModel?.errorMessageTap.send() }
//        )
//    }

    var button: some View {
        TextButtonView(
            title: viewModel.closeButtonTitle,
            style: .primaryWhite,
            size: .large,
            onPressed: viewModel.close.send
        )
        .frame(height: 56)
    }

}

struct DetailTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        DetailTransactionView(
            viewModel: .init(
                rendableTransaction: MockedRendableDetailTransaction.send()
            )
        )
    }
}
