// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import BEPureLayout
import SwiftUI

public class BottomPanel: BECompositionView {
    let child: UIView

    public override init() {
        child = UIView()
        super.init(frame: .zero)
    }

    public required init(@BEViewBuilder builder: Builder) {
        child = builder().build()
        super.init(frame: .zero)
    }
    
    public override func build() -> UIView {
        BEContainer {
            child
        }
            .backgroundColor(color: Asset.Colors.night.color)
            .roundCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 24)
    }
}

public struct BottomActionContainer<Content: View>: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
    let topPadding: Double
    let child: Content

    public init(topPadding: Double = 20, @ViewBuilder child: () -> Content) {
        self.topPadding = topPadding
        self.child = child()
    }

    public var body: some View {
        child
            .padding(.horizontal, 20)
            .padding(.top, topPadding)
            .padding(.bottom, max(safeAreaInsets.bottom, 20))
            .background(Color(Asset.Colors.night.color))
            .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
    }
}
