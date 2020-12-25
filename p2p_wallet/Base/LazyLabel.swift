//
//  LazyLabel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import RxSwift

class LazyLabel<T: Hashable & CustomStringConvertible>: UILabel {
    weak var viewModel: BaseVM<T>?
    
    func subscribed(to viewModel: BaseVM<T>, stringBuilder: ((T) -> String)? = nil) -> Disposable {
        let currentTextColor = textColor
        self.viewModel = viewModel
        self.isUserInteractionEnabled = true
        self.onTap(self, action: #selector(retry))
        return viewModel.state
            .subscribe(onNext: {[weak self] state in
                self?.textColor = currentTextColor
                
                switch state {
                case .loading, .initializing:
                    self?.text = L10n.loading + "..."
                case .loaded(let value):
                    self?.text = stringBuilder?(value) ?? "\(value)"
                case .error:
                    self?.textColor = .red
                    self?.text = L10n.error.uppercaseFirst + ". " +  L10n.retry + "?"
                }
            })
    }
    
    @objc func retry() {
        viewModel?.reload()
    }
}
