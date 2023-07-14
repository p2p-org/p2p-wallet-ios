// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SwiftUI

struct ExplainText: View {
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(LocalizedStringKey(text))
                .apply(style: UIScreen.main.bounds.size.width <= 375 ? .text3 : .text1)
            Spacer()
        }
    }
}

struct ExplainLayoutView<Header: View, Content: View, Hint: View>: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @ViewBuilder let header: Header
    @ViewBuilder let content: Content
    @ViewBuilder let hint: Hint?

    var body: some View {
        VStack {
            // Header
            header
                .frame(maxWidth: .infinity)
                .padding(.top, safeAreaInsets.top + 60)
                .background(Color(.lime))
                .cornerRadius(28)
                .overlay(hint, alignment: .bottom)

            // Content
            content
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.vertical)
        .frame(maxHeight: .infinity)
    }
}
