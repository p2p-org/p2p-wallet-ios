//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import BEPureLayout
import RxCocoa
import RxGesture
import RxSwift
import UIKit

final class ___VARIABLE_scene___RootView: BECompositionView {
//    // MARK: - Subject
//
//    fileprivate let clicked = PublishRelay<Void>()
//    fileprivate let text = PublishRelay<String?>()
//
//    // MARK: - Properties
//
//    let disposeBag = DisposeBag()

    // MARK: - Builder
    override func build() -> UIView {
        UILabel(text: "Hello World")
//            .setup { label in
//                label.rx.onTap
//                    .bind(to: clicked)
//                    .disposed(by: disposeBag)
//
//                text.asDriver()
//                    .drive(label.rx.text)
//                    .disposed(by: disposeBag)
//
//            }
    }
}

//extension Reactive where Base == ___VARIABLE_scene___RootView {
//    var clicked: Observable<Void> {
//        base.clicked.asObservable()
//    }
//    var text: Binder<String?> {
//        Binder(base) { view, text in
//            view.text.accept(text)
//        }
//    }
//}
