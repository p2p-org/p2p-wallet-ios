//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation
import RxSwift
import BEPureLayout

class BEScene: BaseVC {
    override func setUp() {
        super.setUp()
        
        let child = build()
        view.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()
        
        layout()
    }
    
    func layout() {}
    
    deinit {
        print("Deinit \(type(of: self))")
    }
    
    func build() -> UIView {
        fatalError("build method is not implemented")
    }
}
