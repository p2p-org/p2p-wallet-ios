//
//  SendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.11.2022.
//

import SwiftUI

struct SendInputView: View {
    @ObservedObject var viewModel: SendInputViewModel

    @State var detailModal: Bool = false
    @State var freeTransactionModal: Bool = false

    var body: some View {
        VStack {
            Text("Input screen")
            Button { detailModal = true } label: { Text("Open detail") }
            Button { freeTransactionModal = true } label: { Text("Open free transaction") }
        }
        .sheet(isPresented: $detailModal) {
            Text("Detail View")
        }
        .sheet(isPresented: $freeTransactionModal) {
            Text("Free transaction modal")
        }
    }
}

struct SendInputView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputView(viewModel: .init(recipient: .init(
            address: "8JmwhgewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1",
            category: .solanaAddress,
            hasFunds: false
        )))
    }
}
