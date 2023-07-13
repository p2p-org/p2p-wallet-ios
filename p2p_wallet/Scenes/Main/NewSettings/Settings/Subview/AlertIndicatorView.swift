//
//  AlertIndicatorView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/06/2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct AlertIndicatorView: View {
    let fillColor: Color
    
    var body: some View {
        Circle()
            .strokeBorder(Color(.snow), lineWidth: 1)
            .background(Circle().foregroundColor(Color(.rose)).frame(width: 8.5, height: 8.5))
            .frame(width: 9.5, height: 9.5)
    }
}

struct AlertIndicator_Preview: PreviewProvider {
    static var previews: some View {
        ScrollView {
            HStack {
                Spacer()
                AlertIndicatorView(fillColor: Color(.rose))
                Spacer()
            }
        }
        .background(Color(.night).ignoresSafeArea())
    }
}
