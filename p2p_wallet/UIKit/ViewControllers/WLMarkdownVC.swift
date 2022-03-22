//
//  WLMarkdownVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/10/2021.
//

import Foundation

class WLMarkdownVC: WLIndicatorModalVC, CustomPresentableViewController {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }

    var transitionManager: UIViewControllerTransitioningDelegate?
    private let fileName: String
    private lazy var markdownView = WLMarkdownView(bundledMarkdownTxtFileName: fileName)

    init(title: String, bundledMarkdownTxtFileName: String) {
        fileName = bundledMarkdownTxtFileName
        super.init()
        self.title = title
    }

    override func setUp() {
        super.setUp()

        // stack view
        let stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            UILabel(text: title, textSize: 21, weight: .medium)
                .padding(.init(x: 20, y: 0))
            UIView.defaultSeparator()
            BEStackViewSpacing(0)
            markdownView
        }
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))

        markdownView.load()
    }

    override func calculateFittingHeightForPresentedView(targetWidth _: CGFloat) -> CGFloat {
        .greatestFiniteMagnitude
    }

    var dismissalHandlingScrollView: UIScrollView? {
        markdownView.scrollView
    }
}
