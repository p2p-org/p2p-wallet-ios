//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import UIKit
import BEPureLayout

extension ___VARIABLE_scene___ {
    final class RootView: BECompositionView {
        // MARK: - Dependencies

        private let viewModel: ViewModel

        // MARK: - Initializer

        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Builder
        override func build() -> UIView {
            UILabel(text: "Hello World")
        }
    }
}