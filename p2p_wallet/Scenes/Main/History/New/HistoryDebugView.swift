//
//  HistoryDebugView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.05.2023.
//

import SwiftUI

struct HistoryDebugView: View {
    let historyDebug: HistoryDebug = .shared

    var body: some View {
        List {
            Section(header: Text("Wormhole")) {
                Button { historyDebug.clear() } label: { Text("Clear") }
                Button { historyDebug.addWormholeSend() } label: { Text("Add mocked send") }
                Button { historyDebug.addWormholeReceive() } label: { Text("Add mocked receive") }
            }
        }
    }
}

struct HistoryDebugView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryDebugView()
    }
}
