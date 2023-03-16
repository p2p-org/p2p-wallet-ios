//
//  AsyncValueView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.03.2023.
//

import KeyAppKitCore
import SwiftUI

struct AsyncValueView<T, V: View>: View {
    @ObservedObject var value: AsyncValue<T>

    let build: (AsyncValueState<T>) -> V

    var body: some View {
        build(value.state)
            .onAppear { value.fetch() }
    }
}

struct AsyncValueView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncValueView(value: .init(just: "")) { state in
            Text(state.value)
        }
    }
}
