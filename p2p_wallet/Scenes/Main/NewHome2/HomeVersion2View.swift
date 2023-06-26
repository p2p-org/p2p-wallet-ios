//
//  HomeViewVersion2.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 21/06/2023.
//

import KeyAppKitCore
import KeyAppUI
import SwiftUI

struct HomeVersion2View: View {
    @ObservedObject var viewModel: HomeVersion2ViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 24) {
                    Button {
                        viewModel.category = .cash
                    } label: {
                        Text("Cash")
                            .fontWeight(.bold)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .apply(style: .largeTitle)
                            .opacity(viewModel.category == .cash ? 1.0 : 0.3)
                    }
                    Button {
                        viewModel.category = .crypto
                    } label: {
                        Text("Crypto")
                            .fontWeight(.bold)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .apply(style: .largeTitle)
                            .opacity(viewModel.category == .crypto ? 1.0 : 0.3)
                    }
                }
                .padding(.top, 20)
                .padding(.leading, 21)

                switch viewModel.category {
                case .cash:
                    HomeCashView(viewModel: .init())
                case .crypto:
                    HomeCryptoView(viewModel: .init())
                }
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
            HomeVersion2View(viewModel: .init())
        }
    }
}
