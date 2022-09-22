//
//  FixedList.swift
//  p2p_wallet
//
//  Created by Chung Tran on 21/09/2022.
//

import Foundation
import SwiftUI

struct FixedList<Content: View>: View {
    @ViewBuilder public var content: () -> Content

    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
    }

    var body: some View {
        // Market
        List {
            Group {
                content()
            }
            .withoutSeparatorsAfterListContent()
        }
        .listStyle(.plain)
    }
}
