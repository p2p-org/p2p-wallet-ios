// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import SwiftUI

struct InvestView: View {
    var body: some View {
        NavigationView {
            InvestSolendView(viewModel: try! .init(mocked: false))
        }
    }
}
