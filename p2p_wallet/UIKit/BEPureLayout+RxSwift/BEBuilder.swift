//
// Created by Giang Long Tran on 02.02.2022.
//

import Foundation
import RxCocoa
import RxSwift
import BEPureLayout

class BEBuilder<T>: UIView {
    typealias Build<T> = (T) -> UIView

    let driver: Driver<T>
    let build: Build<T>
    let disposeBag = DisposeBag()

    init(driver: Driver<T>, build: @escaping Build<T>) {
        self.driver = driver
        self.build = build
        super.init(frame: .zero)

        driver
            .drive { [weak self] (value: T) in
                guard let self = self else { return }
                for subview in self.subviews {
                    subview.removeFromSuperview()
                }
                
                let view = self.build(value)
                self.addSubview(view)
                view.autoPinEdgesToSuperviewEdges()
            }
            .disposed(by: disposeBag)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
}
