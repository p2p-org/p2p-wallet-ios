//
// Created by Giang Long Tran on 02.02.2022.
//

import Foundation
import RxCocoa
import RxSwift
import BEPureLayout

class BEBuilder<T>: UIView {
    typealias Build<T> = (T) -> UIView
    private let driver: Driver<T>
    private let build: Build<T>
    private let disposeBag = DisposeBag()
    private var child: UIView?
    init(driver: Driver<T>, build: @escaping Build<T>) {
        self.driver = driver
        self.build = build
        super.init(frame: .zero)

        driver
            .drive { [weak self] (value: T) in
                guard let self = self else { return }
                self.child?.alpha = 0.0
                let view = self.build(value)
                self.addSubview(view)
                
                self.child?.removeFromSuperview()
                self.child = view
            }
            .disposed(by: disposeBag)
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        view.autoPinEdgesToSuperviewEdges()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
}
