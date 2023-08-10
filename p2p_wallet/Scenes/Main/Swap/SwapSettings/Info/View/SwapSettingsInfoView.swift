import SkeletonUI
import SwiftUI

struct SwapSettingsInfoView: View {
    @ObservedObject var viewModel: SwapSettingsInfoViewModel

    var body: some View {
        VStack {
            Image(viewModel.image)
            HStack(spacing: 16) {
                Image(.transactionFee)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title)
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .foregroundColor(Color(.night))
                    Text(viewModel.subtitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(uiFont: .font(of: .label1))
                        .foregroundColor(Color(.night))
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color(.cloud))
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
                        .foregroundColor(Color(.snow))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.night))
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
            ForEach(Array(zip(fees.indices, fees)), id: \.0) { _, fee in
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
                    .foregroundColor(Color(.night))
                    .skeleton(with: isLoading, size: .init(width: 100, height: 16))
                Text(subtitle)
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(.mountain))
                    .skeleton(with: isLoading, size: .init(width: 52, height: 12))
            }
            Spacer()
            Text(rightTitle ?? "")
                .font(uiFont: .font(of: .label1))
                .foregroundColor(Color(.mountain))
                .skeleton(with: isLoading, size: .init(width: 52, height: 12))
        }
    }
}
