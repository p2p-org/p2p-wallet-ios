//
//  BackupManuallyBaseVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/06/2021.
//

import Action
import Foundation
import Resolver

class BackupManuallyBaseVC: BaseVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }

    lazy var headerView = UIStackView(axis: .horizontal, distribution: .equalSpacing, arrangedSubviews: [
        UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 21, weight: .semibold),
        UILabel(text: L10n.done, textSize: 17, textColor: .h5887ff)
            .onTap(self, action: #selector(back)),
    ])
        .padding(.init(x: 20, y: 0))

    lazy var rootView: ScrollableVStackRootView = {
        let rootView = ScrollableVStackRootView(forAutoLayout: ())
        rootView.scrollView.contentInset = .init(only: .top, inset: 20)
        rootView.stackView.spacing = 20
        rootView.stackView.addArrangedSubviews([
            phrasesListView,
        ])
        return rootView
    }()

    lazy var phrasesListView: WLPhrasesListView = {
        let listView = WLPhrasesListView(forAutoLayout: ())
        listView.copyToClipboardAction = CocoaAction { [weak self] in
            self?.buttonCopyToClipboardDidTouch()
            return .just(())
        } // phrase
        listView.setUp(phrases: phrases)
        return listView
    }()

    lazy var stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
        headerView
        BEStackViewSpacing(20)
        UIView.defaultSeparator()
        rootView
            .padding(.init(x: 20, y: 0))
    }

    var phrases: [String] {
        storage.account?.phrase ?? []
    }

    @Injected var storage: ICloudStorageType & AccountStorageType & NameStorageType
    @Injected private var clipboardManager: ClipboardManagerType
    @Injected private var notificationsManager: NotificationsServiceType

    override func setUp() {
        super.setUp()
        // header view
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))
    }

    func buttonCopyToClipboardDidTouch() {
        clipboardManager.copyToClipboard(phrases.joined(separator: " "))
        notificationsManager.showInAppNotification(.done(L10n.copiedToClipboard))
    }
}
