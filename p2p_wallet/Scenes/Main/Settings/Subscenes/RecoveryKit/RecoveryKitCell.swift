// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct RecoveryKitCell: View {
    let title: String

    var body: some View {
        Button {} label: {
            HStack {
                Image(uiImage: .keyIcon)
                Text(title)
                    .apply(style: .text2)
                Spacer()
                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
            }.padding(.horizontal, 16)
        }
        .frame(height: 55)
        .foregroundColor(Color(Asset.Colors.night.color))
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
        )
    }
}

struct RecoveryKitCell_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.gray)
            RecoveryKitCell(title: "Seed phrase")
        }
    }
}
