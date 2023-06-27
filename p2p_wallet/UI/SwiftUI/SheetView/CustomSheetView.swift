//
//  PopupView.swift
//  p2p_wallet
//
//  Created by Ivan on 01.10.2022.
//

import SwiftUI

struct CustomSheetView: View {
    let headerState: HeaderState
    let close: () -> Void

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .sheetHeader(title: L10n.depositToEarnAYield, close: close)
            .frame(maxWidth: .infinity)
            .background(RoundedCorners(color: .white, tl: 20, tr: 20))
            .transition(.move(edge: .bottom))
            .previewLayout(.sizeThatFits)
    }
}

// MARK: - Header

extension CustomSheetView {
    enum HeaderState {
        case none
        case visible(title: String, withSeparator: Bool = true)
    }
}
