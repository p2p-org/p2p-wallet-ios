//
//  RxSwift + Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 06.04.2022.
//

import RxCocoa
import RxSwift

extension ObservableType {
    func mapToVoid() -> Observable<Void> {
        map { _ in }
    }

    func asDriver() -> Driver<Element> {
        observe(on: MainScheduler.instance)
            .asDriver(onErrorDriveWith: .empty())
    }

    func mapTo<Result>(_ value: Result) -> Observable<Result> {
        map { _ in value }
    }

    func materializeAndFilterComplete() -> Observable<RxSwift.Event<Element>> {
        materialize().filter { !$0.event.isCompleted }
    }
}

extension Observable where Element: EventConvertible {
    func events() -> (Observable<Element.Element>, Observable<Error>) {
        let elements = elements()
        let errors = errors()
        return (elements, errors)
    }
}

extension ObservableType where Element: EventConvertible {
    /**
     Returns an observable sequence containing only next elements from its input
     - seealso: [materialize operator on reactivex.io](http://reactivex.io/documentation/operators/materialize-dematerialize.html)
     */
    func elements() -> Observable<Element.Element> {
        compactMap(\.event.element)
    }

    /**
     Returns an observable sequence containing only error elements from its input
     - seealso: [materialize operator on reactivex.io](http://reactivex.io/documentation/operators/materialize-dematerialize.html)
     */
    func errors() -> Observable<Error> {
        compactMap(\.event.error)
    }
}
