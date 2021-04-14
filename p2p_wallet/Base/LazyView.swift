//
//  LazyView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift
import BECollectionView

private var key: UInt8 = 0
protocol LazyView: UIView {
    associatedtype T: Hashable
    func handleDataLoaded(_ data: T)
    func handleError(_ error: Error)
}

private class Indicator: UIActivityIndicatorView {}
extension LazyView {
    func subscribed(
        to viewModel: BaseVM<T>,
        onError: ((Error) -> Void)? = nil
    ) -> Disposable {
        self.isUserInteractionEnabled = true
//        self.onTap(self, action: #selector(retry))
        return viewModel.state
            .subscribe(onNext: {[weak self] state in
                guard let self = self else {return}
                switch state {
                case .loading, .initializing:
                    let spinner = Indicator(style: .medium)
                    spinner.color = .textBlack
                    spinner.translatesAutoresizingMaskIntoConstraints = false
                    self.addSubview(spinner)
                    spinner.autoCenterInSuperview()
                    spinner.startAnimating()
                case .loaded(let value):
                    self.subviews.filter {$0 is Indicator}.forEach {$0.removeFromSuperview()}
                    self.handleDataLoaded(value)
                case .error(let error):
                    self.subviews.filter {$0 is Indicator}.forEach {$0.removeFromSuperview()}
                    self.handleError(error)
                }
            })
    }
    
    func subscribed(
        to viewModel: BEViewModel<T>,
        onError: ((Error) -> Void)? = nil
    ) -> Disposable {
        self.isUserInteractionEnabled = true
//        self.onTap(self, action: #selector(retry))
        return viewModel.stateObservable
            .subscribe(onNext: {[weak self] state in
                guard let self = self else {return}
                switch state {
                case .loading, .initializing:
                    let spinner = Indicator(style: .medium)
                    spinner.color = .textBlack
                    spinner.translatesAutoresizingMaskIntoConstraints = false
                    self.addSubview(spinner)
                    spinner.autoCenterInSuperview()
                    spinner.startAnimating()
                case .loaded:
                    self.subviews.filter {$0 is Indicator}.forEach {$0.removeFromSuperview()}
                    self.handleDataLoaded(viewModel.data)
                case .error:
                    self.subviews.filter {$0 is Indicator}.forEach {$0.removeFromSuperview()}
                    if let error = viewModel.error {
                        self.handleError(error)
                    }
                }
            })
    }
}
