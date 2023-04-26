//
//  SupportedTokensView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import KeyAppUI
import SwiftUI

struct SupportedTokensView: View {
    @ObservedObject var viewModel: SupportedTokensViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(uiImage: UIImage.buttonSearch)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                TextField(L10n.search, text: $viewModel.filter)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor(red: 0.463, green: 0.463, blue: 0.502, alpha: 0.12)))
            )
            .padding(.horizontal, 16)

            ScrollView {
                if viewModel.tokens.isEmpty, viewModel.filter.isEmpty {
                    SwiftUI.EmptyView()
                } else if !viewModel.filter.isEmpty {
                    if viewModel.tokens.isEmpty {
                        VStack(spacing: 12) {
                            Image(uiImage: .womanNotFound)
                                .resizable()
                                .frame(width: 220, height: 165)
                                .padding(.top, 40)
                            Text(L10n.TokenNotFound.tryAnotherOne)
                                .apply(style: .text1)
                        }
                    } else {
                        HStack {
                            Text(L10n.hereSWhatWeFound.uppercased())
                                .apply(style: .caps)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .padding(.leading, 16)
                                .padding(.top, 32)
                                .padding(.bottom, 12)
                            Spacer()
                        }
                        list
                    }
                } else {
                    SupportedTokensBannerView()
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    list
                }
            }
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
        .background(
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()
        )
    }

    var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokens, id: \.id) { item in
                VStack(spacing: 0) {
                    Button {
                        viewModel.onTap(item)
                    } label: {
                        SupportedTokenItemView(item: item)
                    }

                    if item.id != viewModel.tokens.last?.id {
                        Divider()
                            .frame(height: 1)
                            .overlay(Color(Asset.Colors.rain.color))
                            .padding(.top, 10)
                            .padding(.leading, 20)
                    } else {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 0)
                    }
                }
                .frame(height: 72)
            }
        }
        .padding(.top, 16)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}

struct SupportedTokensView_Previews: PreviewProvider {
    static var previews: some View {
        SupportedTokensView(
            viewModel: .init(
                mock: [
                    SupportedTokenItem(
                        icon: .image(.solanaIcon),
                        name: "USD Coin",
                        symbol: "USDC",
                        availableNetwork: [.ethereum, .solana]
                    ),
                    SupportedTokenItem(
                        icon: .image(.usdt),
                        name: "Tether USD",
                        symbol: "USDT",
                        availableNetwork: [.ethereum, .solana]
                    ),
                    SupportedTokenItem(
                        icon: .image(.usdc),
                        name: "USD Coin",
                        symbol: "USDC",
                        availableNetwork: [.solana]
                    ),
                ]
            )
        )
    }
}
