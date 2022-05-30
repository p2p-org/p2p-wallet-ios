//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

final class ___VARIABLE_scene___RootView: BECompositionView {
//    // MARK: - Subject
//
//    let clicked = PublishRelay<Void>()
//
//    // MARK: - Properties
//
//    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    
    fileprivate let label = UILabel(text: "Hello World")

    // MARK: - Builder
    override func build() -> UIView {
        label
//            .onTap { [weak self] in
//                self?.clicked.accept(())
//            }
    }
}

//extension Reactive where Base == ___VARIABLE_scene___RootView {
//    var clicked: Observable<Void> {
//        base.clicked.asObservable()
//    }
//    var text: Binder<String?> {
//        Binder(base) { view, text in
//            view.label.text = text
//        }
//    }
//}
