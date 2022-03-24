//___FILEHEADER___

import Foundation

extension ___FILEBASENAME___ {
    class ViewController: BEScene {
        // MARK: - Dependencies
        
        private let viewModel: ___FILEBASENAME___ViewModelType

        // MARK: - Properties
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        // MARK: - Initializer
        
        init(viewModel: ___FILEBASENAME___ViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Builder
        override func build() -> UIView {
            BEContainer {}
        }
    }
}
