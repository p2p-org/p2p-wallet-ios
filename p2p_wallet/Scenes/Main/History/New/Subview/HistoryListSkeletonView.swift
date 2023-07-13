//
//  NewHistoryListSkeletonView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.02.2023.
//

import KeyAppUI
import SwiftUI

struct HistoryListSkeletonView: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color(.rain))
                .frame(width: 48, height: 48)
            VStack(spacing: 8) {
                RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                    .fill(Color(.rain))
                    .frame(maxWidth: 120)
                    .frame(height: 12)
                
                RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                    .fill(Color(.rain))
                    .frame(maxWidth: 120)
                    .frame(height: 12)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
    }
}

struct HistoryListSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryListSkeletonView()
    }
}
