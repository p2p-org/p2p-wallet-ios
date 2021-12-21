//
// Created by Giang Long Tran on 13.12.21.
//

import Foundation
import RxSwift
import BEPureLayout

class BEScene: BEViewController {
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        let child = build()
        view.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()
    }
    
    deinit {
        print("Deinit \(type(of: self))")
    }
    
    func build() -> UIView {
        fatalError("build method is not implemented")
    }
}
