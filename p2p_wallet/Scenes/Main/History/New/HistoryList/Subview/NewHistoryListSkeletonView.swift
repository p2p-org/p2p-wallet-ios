//
//  NewHistoryListSkeletonView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.02.2023.
//

import KeyAppUI
import SwiftUI

struct NewHistoryListSkeletonView: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 48, height: 48)
            VStack(spacing: 8) {
                RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                    .fill(Color(Asset.Colors.rain.color))
                    .frame(maxWidth: 120)
                    .frame(height: 12)
                
                RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                    .fill(Color(Asset.Colors.rain.color))
                    .frame(maxWidth: 120)
                    .frame(height: 12)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
    }
}

struct NewHistoryListSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        NewHistoryListSkeletonView()
    }
}
