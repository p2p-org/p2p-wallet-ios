//
//  ObservableType+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType {
    func withPrevious() -> Observable<(Element?, Element)> {
        scan([], accumulator: { previous, current in
            Array(previous + [current]).suffix(2)
        })
            .map { arr -> (previous: Element?, current: Element) in
                (arr.count > 1 ? arr.first : nil, arr.last!)
            }
    }
}

extension ObservableType {
    func filterComplete() -> Observable<Element> {
        materializeAndFilterComplete().dematerialize()
    }

    func materializeAndFilterComplete() -> Observable<RxSwift.Event<Element>> {
        materialize().filter { !$0.event.isCompleted }
    }

    func asDriver() -> RxCocoa.Driver<Element> {
        observe(on: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
    }

    func mapTo<Result>(_ value: Result) -> Observable<Result> {
        map { _ in value }
    }

    func unwrap<R>() -> Observable<R> where Element == R? {
        compactMap { $0 }
    }

    func optionallWrap() -> Observable<Element?> {
        map { Optional($0) }
    }
}

extension ObservableType {
    func mapToVoid() -> Observable<Void> {
        map { _ in }
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func mapToVoid() -> Single<Void> {
        map { _ in }
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

extension Timer {
    static func observable(
        seconds: Int,
        scheduler: SchedulerType = MainScheduler.instance
    ) -> Observable<Void> {
        Observable<Int>.timer(.seconds(0), period: .seconds(seconds), scheduler: scheduler)
            .map { _ in () }
    }
}
