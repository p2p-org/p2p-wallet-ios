//
//  BaseVerticalStackVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

class BaseVStackVC: BaseVC {
    var padding: UIEdgeInsets { UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) }
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical, contentInset: padding)
    lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewDidTouch))

    override func setUp() {
        super.setUp()

        view.addGestureRecognizer(tapGesture)
        // scroll view for flexible height
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()

        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }

    @objc func viewDidTouch() {
        view.endEditing(true)
    }
}
