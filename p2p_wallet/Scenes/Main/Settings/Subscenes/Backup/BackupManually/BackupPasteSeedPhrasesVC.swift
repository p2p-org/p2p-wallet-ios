//
//  BackupPasteSeedPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/06/2021.
//

import Combine
import CombineCocoa
import Foundation

class BackupPasteSeedPhrasesVC: WLEnterPhrasesVC {
    private let rightBarButton = UIBarButtonItem(
        title: L10n.done,
        style: .done,
        target: BackupPasteSeedPhrasesVC.self,
        action: #selector(buttonNextDidTouch)
    )

    override func setUp() {
        super.setUp()

        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.title = L10n.backingUp

        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(toSuperviewSafeArea: .top)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)

        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        scrollView.autoPinEdge(.top, to: .bottom, of: separator)

        dismissAfterCompletion = false
    }

    override func bind() {
        super.bind()
        Publishers.CombineLatest(
            textView.textPublisher
                .map { [weak self] _ in self?.textView.getPhrases().isEmpty == false },
            error.map { $0 == nil }
        )
            .map { $0 && $1 }
            .replaceError(with: false)
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: rightBarButton)
            .store(in: &subscriptions)
    }
}
