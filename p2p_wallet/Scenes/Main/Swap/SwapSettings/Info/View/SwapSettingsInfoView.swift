//
//  SwapSettingsInfoView.swift
//  p2p_wallet
//
//  Created by Ivan on 02.03.2023.
//

import SwiftUI
import KeyAppUI
import SkeletonUI

struct SwapSettingsInfoView: View {
    @ObservedObject var viewModel: SwapSettingsInfoViewModel
    
    var body: some View {
        VStack {
            Image(uiImage: viewModel.image)
            HStack(spacing: 16) {
                Image(uiImage: .transactionFee)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title)
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Text(viewModel.subtitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(uiFont: .font(of: .label1))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(12)
            .padding(.bottom, 30)
            
            switch viewModel.loadableFee {
            case .loading:
                feeView(
                    title: L10n.liquidityFee,
                    subtitle: "",
                    rightTitle: nil,
                    isLoading: true
                )
                    .padding(.bottom, 30)
            case let .loaded(fees) where !fees.isEmpty:
                feesView(fees: fees)
                    .padding(.bottom, 30)
            default:
                HStack {}
            }
            
            Button(
                action: {
                    viewModel.closeClicked()
                },
                label: {
                    Text(viewModel.buttonTitle)
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .sheetHeader(title: nil, withSeparator: false)
    }

    private func feesView(fees: [SwapSettingsInfoViewModel.Fee]) -> some View {
        VStack(spacing: 24) {
            ForEach(Array(zip(fees.indices, fees)), id: \.0) { index, fee in
                feeView(
                    title: fee.title,
                    subtitle: fee.subtitle,
                    rightTitle: fee.amount
                )
            }
        }
    }

    private func feeView(
        title: String,
        subtitle: String,
        rightTitle: String?,
        isLoading: Bool = false
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .skeleton(with: isLoading, size: .init(width: 100, height: 16))
                Text(subtitle)
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .skeleton(with: isLoading, size: .init(width: 52, height: 12))
            }
            Spacer()
            Text(rightTitle ?? "")
                .font(uiFont: .font(of: .label1))
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .skeleton(with: isLoading, size: .init(width: 52, height: 12))
        }
    }
}
