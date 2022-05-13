//
//  BackupPasteSeedPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/06/2021.
//

import Foundation
import RxSwift

class BackupPasteSeedPhrasesVC: WLEnterPhrasesVC {
    private let rightBarButton = UIBarButtonItem(
        title: L10n.done,
        style: .done,
        target: self,
        action: #selector(buttonNextDidTouch)
    )

    override func setUp() {
        super.setUp()

        rightBarButton.setTitleTextAttributes([.foregroundColor: UIColor.h5887ff], for: .normal)
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
        Observable.combineLatest(
            textView.rx.text
                .map { [weak self] _ in self?.textView.getPhrases().isEmpty == false },
            error.map { $0 == nil }
        )
            .map { $0 && $1 }
            .asDriver(onErrorJustReturn: false)
            .drive(rightBarButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}
