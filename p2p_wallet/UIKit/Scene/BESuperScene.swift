//
// Created by Giang Long Tran on 11.01.22.
//

import UIKit

class BESuperScene: BaseVC {
    override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
    
    func root() -> UIViewController {
        fatalError("root method is not implemented")
    }
    
    override func setUp() {
        let navVC = UINavigationController(rootViewController: root())
        
        addChild(navVC)
        navVC.view.autoPinEdgesToSuperviewEdges()
        view.addSubview(navVC.view)
        navVC.didMove(toParent: self)
    }
}
