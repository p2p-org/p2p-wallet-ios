//
//  DebugText.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.06.2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct DebugText: View {
    let title: String
    let value: String

    var body: some View {
        Button {
            UIPasteboard.general.setValue(value, forPasteboardType: UTType.plainText.identifier)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(value)
            }
        }
    }
}

struct DebugText_Previews: PreviewProvider {
    static var previews: some View {
        DebugText(title: "Some property", value: "Value")
    }
}
