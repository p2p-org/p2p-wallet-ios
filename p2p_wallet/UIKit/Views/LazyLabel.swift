//
//  LazyLabel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/12/2020.
//

import Foundation
import LazySubject
import RxSwift

class LazyLabel<T: Hashable & CustomStringConvertible>: UILabel {
    weak var subject: LazySubject<T>?

    func subscribed(to subject: LazySubject<T>, stringBuilder: ((T) -> String)? = nil) -> Disposable
    {
        let currentTextColor = textColor
        self.subject = subject
        isUserInteractionEnabled = true
        onTap(self, action: #selector(retry))
        return subject.observable
            .subscribe(onNext: { [weak self] state in
                self?.textColor = currentTextColor

                switch state {
                case .loading, .initializing:
                    self?.text = L10n.loading + "..."
                case .loaded:
                    if let value = subject.value {
                        self?.text = stringBuilder?(value) ?? "\(value)"
                    }
                case .error:
                    self?.textColor = .red
                    self?.text = L10n.error.uppercaseFirst + ". " + L10n.retry + "?"
                }
            })
    }

    @objc func retry() {
        subject?.reload()
    }
}
