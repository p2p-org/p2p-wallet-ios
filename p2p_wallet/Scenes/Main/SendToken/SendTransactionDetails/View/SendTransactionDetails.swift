//
//  SendTransactionDetails.swift
//  p2p_wallet
//
//  Created by Ivan on 28.11.2022.
//

import Combine
import KeyAppUI
import SwiftUI

private enum Constants {
    static let verticalSpacing: CGFloat = 0
    static let verticalPadding: CGFloat = 16
    static let cellHeight: CGFloat = 90
    static let imageRightSpacing: CGFloat = 16
    static let contentHorizontalSpacing: CGFloat = 16
    static let imageSize: CGFloat = 48
    static let textSpacing: CGFloat = 2
    static let buttonTopPadding: CGFloat = 16
    static let textHStackSpacing: CGFloat = 4
    static let infoHeight: CGFloat = 14
}

struct SendTokenDetails: View {
    private let cancelSubject = PassthroughSubject<Void, Never>()

    private let model: [CellModel]

    init(model: Model) {
        self.model = [
            CellModel(
                title: L10n.recipientSAddress,
                subtitle: (model.recipientAddress, nil),
                image: .recipientAddress
            ),
            CellModel(
                title: L10n.recipientGets,
                subtitle: (model.recipientAmount, model.recipientAmountUsd),
                image: .recipientGet
            ),
            CellModel(
                title: L10n.transactionFee,
                subtitle: (model.transactionFee, nil),
                image: .transactionFee,
                isFree: true
            ),
            CellModel(
                title: L10n.accountCreationFee,
                subtitle: (model.accountCreationFee, model.accountCreationFeeUsd),
                image: .accountCreationFee,
                info: {}
            ),
            CellModel(
                title: L10n.total,
                subtitle: (model.total, model.totalUsd),
                image: .totalSend
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            ForEach(model) { model in
                cellView(model: model)
            }
            Button(
                action: {
                    cancelSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .bold))
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                        .padding(.top, Constants.buttonTopPadding)
                }
            )
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.contentHorizontalSpacing)
        .sheetHeader(title: L10n.transactionDetails, withSeparator: false) {
            cancelSubject.send()
        }
    }

    private func cellView(model: CellModel) -> some View {
        HStack(spacing: Constants.imageRightSpacing) {
            Image(uiImage: model.image)
                .frame(width: Constants.imageSize, height: Constants.imageSize)
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                HStack(spacing: Constants.textHStackSpacing) {
                    Text(model.title)
                        .lineLimit(1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .semibold))
                    if model.info != nil {
                        Button(
                            action: {
                                model.info?()
                            },
                            label: {
                                Image(uiImage: .feeInfo.withRenderingMode(.alwaysOriginal))
                                    .resizable()
                                    .frame(
                                        width: Constants.infoHeight,
                                        height: Constants.infoHeight
                                    )
                            }
                        )
                    }
                }
                HStack(spacing: Constants.textHStackSpacing) {
                    Text(model.subtitle.0)
                        .foregroundColor(Color(model.isFree ? Asset.Colors.mint.color : Asset.Colors.night.color))
                        .font(uiFont: .font(of: .label1, weight: model.isFree ? .semibold : .regular))
                    if let additionalText = model.subtitle.1 {
                        Text("(\(additionalText))")
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .font(uiFont: .font(of: .label1))
                    }
                }
            }
        }
        .frame(height: Constants.cellHeight)
    }
}

// MARK: - Cell Model

private extension SendTokenDetails {
    struct CellModel: Identifiable {
        let title: String
        let subtitle: (String, String?)
        let image: UIImage
        var isFree: Bool = false
        var info: (() -> Void)?
        
        var id: String { title }
    }
}

// MARK: - Model

extension SendTokenDetails {
    struct Model {
        let recipientAddress: String
        let recipientAmount: String
        let recipientAmountUsd: String
        let transactionFee: String
        let accountCreationFee: String
        let accountCreationFeeUsd: String
        let total: String
        let totalUsd: String
    }
}

// MARK: - View Height

extension SendTokenDetails {
    var viewHeight: CGFloat {
        624
    }
}

struct SendTokenDetails_Previews: PreviewProvider {
    static var previews: some View {
        SendTokenDetails(model: SendTokenDetails.Model(
            recipientAddress: "2PfZSWbqREfwGzWESqZ1quaMHXsb67Q4cbYuaY6yQxfS",
            recipientAmount: "10 USDC",
            recipientAmountUsd: "$10",
            transactionFee: "Free (99 left for today)",
            accountCreationFee: "0.028813 USDC",
            accountCreationFeeUsd: "$0.03",
            total: "10.028813 USDC",
            totalUsd: "$10.02"
        ))
    }
}
