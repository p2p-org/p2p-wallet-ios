//
//  BackupPasteSeedPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/06/2021.
//

import Foundation
import RxSwift

class BackupPasteSeedPhrasesVC: WLEnterPhrasesVC {
    // MARK: - Subviews
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(forAutoLayout: ())
        navigationBar.centerItems.addArrangedSubviews {
            UILabel(text: L10n.backingUp, textSize: 17, weight: .semibold, textAlignment: .center)
        }
        navigationBar.rightItems.subviews.forEach {$0.removeFromSuperview()}
        navigationBar.rightItems.addArrangedSubviews {
            rightBarButton
        }
        navigationBar.backButton.onTap(self, action: #selector(back))
        return navigationBar
    }()
    lazy var rightBarButton = UIButton(label: L10n.done, labelFont: .systemFont(ofSize: 17, weight: .medium), textColor: .h5887ff)
        .onTap(self, action: #selector(buttonNextDidTouch))
    
    override func setUp() {
        super.setUp()
        
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(.top, to: .bottom, of: navigationBar)
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
                .map {[weak self] _ in (self?.textView.getPhrases().isEmpty == false)},
            error.map {$0 == nil}
        )
            .map {$0 && $1}
            .asDriver(onErrorJustReturn: false)
            .drive(rightBarButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}
