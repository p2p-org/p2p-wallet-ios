import Foundation
import KeyAppUI
import SwiftUI

struct HomeBankTransferAccountView: View {
    let renderable: any RenderableAccount

    let onTap: (() -> Void)?
    let onButtonTap: (() -> Void)?

    var body: some View {
        FinanceBlockView(
            leadingItem: FinanceBlockLeadingItem(
                image: .image(.iconUpload),
                iconSize: CGSize(width: 50, height: 50),
                isWrapped: false
            ),
            centerItem: FinancialBlockCenterItem(
                title: renderable.title,
                subtitle: renderable.subtitle
            ),
            trailingItem: FinancialBlockTrailingItem(
                isLoading: renderable.isLoading,
                detail: renderable.detail,
                onButtonTap: onButtonTap
            )
        )
        .onTapGesture {
            onTap?()
        }
    }
}
