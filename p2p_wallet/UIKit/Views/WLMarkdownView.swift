//
//  WLMarkdownView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/10/2021.
//

import BEPureLayout
import Down
import Foundation
import UIKit

class WLMarkdownView: BEView {
    // MARK: - Properties

    private let fileName: String

    let scrollView = ContentHuggingScrollView(
        scrollableAxis: .vertical,
        contentInset: .init(top: 20, left: 20, bottom: 0, right: 20)
    )
    private let label = UILabel(text: nil, textSize: 15, numberOfLines: 0)

    init(bundledMarkdownTxtFileName: String) {
        fileName = bundledMarkdownTxtFileName
        super.init(frame: .zero)
    }

    override func commonInit() {
        super.commonInit()

        addSubview(scrollView)
        scrollView.autoPinEdgesToSuperviewEdges()

        scrollView.contentView.addSubview(label)
        label.autoPinEdgesToSuperviewEdges()
    }

    func load() {
        // markdown
        showIndetermineHud()

        let color = traitCollection.userInterfaceStyle == .dark ? "white" : "black"
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            // TODO: - Localization
            let filepath = Bundle.main.path(forResource: self.fileName, ofType: "txt")!
            let contents = try! String(contentsOfFile: filepath)

            let down = Down(markdownString: contents)
            let attributedString = try! down.toAttributedString(
                .default,
                stylesheet: "* {font-family: Helvetica; font-size: 15px; color: \(color); } code, pre { font-family: Menlo; font-size: 15px }"
            )

            DispatchQueue.main.async { [weak self] in
                self?.hideHud()
                self?.label.attributedText = attributedString
            }
        }
    }
}
