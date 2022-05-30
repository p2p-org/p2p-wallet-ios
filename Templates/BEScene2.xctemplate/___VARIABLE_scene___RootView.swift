//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import UIKit
import BEPureLayout

final class ___VARIABLE_scene___RootView: BECompositionView {
    // MARK: - Dependencies

    private let viewModel: ___VARIABLE_scene___ViewModel

    // MARK: - Initializer

    init(viewModel: ___VARIABLE_scene___ViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - Builder
    override func build() -> UIView {
        UILabel(text: "Hello World")
    }
}
