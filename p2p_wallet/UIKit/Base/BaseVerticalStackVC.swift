//
//  BaseVerticalStackVC.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation

class BaseVStackVC: BaseVC {
    lazy var scrollView = ContentHuggingScrollView(scrollableAxis: .vertical)
    lazy var stackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)

    override func setUp() {
        super.setUp()
        view.backgroundColor = .white

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewDidTouch))
        view.addGestureRecognizer(tapGesture)
        // scroll view for flexible height
        view.addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        scrollView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 16)

        // stackView
        scrollView.contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: padding)
    }

    @objc func viewDidTouch() {
        view.endEditing(true)
    }
}
