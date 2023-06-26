//
//  HomeViewVersion2.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 21/06/2023.
//

import KeyAppKitCore
import KeyAppUI
import SwiftUI

struct HomeViewVersion2: View {
    @ObservedObject var viewModel: HomeVersion2ViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 24) {
                    Button {} label: {
                        Text("Cash")
                            .fontWeight(.bold)
                            .apply(style: .largeTitle)
                    }
                    Button {} label: {
                        Text("Crypto")
                            .fontWeight(.bold)
                            .apply(style: .largeTitle)
                            .opacity(0.3)
                    }
                }
                .padding(.top, 20)
                .padding(.leading, 21)
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {} label: {
                            Text("All Accounts")
                                .font(.custom("SF Pro Text", size: 16))
                                .fontWeight(.regular)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                            Image(uiImage: UIImage.chevronDown)
                                .foregroundColor(Color(Asset.Colors.silver.color))
                        }

                        HStack(spacing: 4) {
                            Text(viewModel.totalAmountInFiat)
                                .font(.custom("SF Pro Rounded", size: 44))
                            Spacer()
                            HorizontalTokenIconView(icons: viewModel.iconsURL)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    HStack(spacing: 12) {
                        NewTextButton(
                            title: "Add money",
                            size: .small,
                            style: .primaryWhite,
                            expandable: true,
                            trailing: Asset.MaterialIcon.add.image
                        ) {}
                        NewTextButton(
                            title: "Withdraw",
                            size: .small,
                            style: .second,
                            expandable: true,
                            trailing: Asset.MaterialIcon.arrowUpward.image
                        ) {}
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                }
                .background(Color(Asset.Colors.snow.color)).cornerRadius(radius: 20, corners: .allCorners)
                .padding(.horizontal, 16)
                ZStack(alignment: .leading) {
                    Color(UIColor(red: 0.804, green: 0.965, blue: 0.804, alpha: 1))
                        .cornerRadius(radius: 16, corners: .allCorners)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Send money with zero fees")
                            .fontWeight(.semibold)
                            .apply(style: .text2)
                            .multilineTextAlignment(.leading)
                        Text("Save on commissions and make transfers easier!")
                            .apply(style: .label1)

                        NewTextButton(title: "Get started", size: .small, style: .inverted) {}
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: 170)
                    .padding(.vertical, 16)
                    .padding(.leading, 16)
                }
                .overlay(alignment: .topTrailing) {
                    Button {} label: {
                        Image(uiImage: UIImage.closeIcon)
                    }
                    .foregroundColor(Color(Asset.Colors.silver.color))
                    .offset(x: -19.33, y: 19.33)
                }
                .overlay(alignment: .trailing) {
                    Image(uiImage: UIImage.coinDrop)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 16.5)
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {} label: {
                    Text("@username.key")
                        .fontWeight(.bold)
                        .apply(style: .text3)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .padding(.vertical, 4)
                        .padding(.leading, 16)
                    Image(uiImage: UIImage.copyLined)
                        .padding(.trailing, 14)
                }
                .frame(height: 36)
                .background(Color(Asset.Colors.snow.color))
                .cornerRadius(radius: 80, corners: .allCorners)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: {
                    Image(uiImage: Asset.MaterialIcon.moreHoriz.image)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .frame(width: 36, height: 36)
                        .background(Color(Asset.Colors.snow.color))
                        .cornerRadius(radius: 48, corners: .allCorners)
                }
            }
        }
        .background(Color(Asset.Colors.smoke.color).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeViewVersion2_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeViewVersion2(viewModel: .init(totalAmountInFiat: "$25",
                                              iconsURL: [URL(string: SolanaToken.usdc.logoURI!)!]))
        }
    }
}
