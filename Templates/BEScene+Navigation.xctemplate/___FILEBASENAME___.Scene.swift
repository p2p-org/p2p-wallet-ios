//___FILEHEADER___

import Foundation

extension ___FILEBASENAME___ {
    class Scene: BEScene {
        @BENavigationBinding private var viewModel: ___FILEBASENAME___SceneModel!

        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override func build() -> UIView {
            BEContainer {}
        }
    }
}
