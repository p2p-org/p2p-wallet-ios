//
//  DeleteRequestSuccess.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.11.2022.
//

import SwiftUI
import KeyAppUI

struct DeleteRequestSuccessView: View {
    var onDone: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .catFail)
            Text(L10n.deletingYourAccountWillTakeUpTo30Days)
                .padding(.vertical, 20)
            TextButtonView(title: L10n.done, style: .second, size: .large) { onDone?() }
                .frame(height: TextButton.Size.large.height)
                .padding(.horizontal, 24)
        }
        .sheetHeader(title: L10n.yourRemovalRequestHasBeenAccepted, withSeparator: false)
        .multilineTextAlignment(.center)
    }
}

extension DeleteRequestSuccessView {
    var viewHeight: CGFloat { 510 }
}

struct DeleteRequestSuccess_Previews: PreviewProvider {
    static var previews: some View {
        DeleteRequestSuccessView()
    }
}
