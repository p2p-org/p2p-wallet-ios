//
//  LazyView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation
import RxSwift

private var key: UInt8 = 0
protocol LazyView: UIView {
    associatedtype T: Hashable
    func handleDataLoaded(_ data: T)
    func handleError(_ error: Error)
}

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
                    let spinner = UIActivityIndicatorView(style: .gray)
                    spinner.color = .textBlack
                    spinner.translatesAutoresizingMaskIntoConstraints = false
                    self.addSubview(spinner)
                    spinner.autoCenterInSuperview()
                    spinner.startAnimating()
                    objc_setAssociatedObject(self, &key, spinner, .OBJC_ASSOCIATION_RETAIN)
                case .loaded(let value):
                    (objc_getAssociatedObject(self, &key) as? UIActivityIndicatorView)?.removeFromSuperview()
                    self.handleDataLoaded(value)
                case .error(let error):
                    (objc_getAssociatedObject(self, &key) as? UIActivityIndicatorView)?.removeFromSuperview()
                    self.handleError(error)
                }
            })
    }
}
