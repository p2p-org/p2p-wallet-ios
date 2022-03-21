//
//  DAppContainer.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import RxSwift
import UIKit
import WebKit

extension DAppContainer {
    class RootView: BEView {
        // MARK: - Constants

        private let disposeBag = DisposeBag()

        // MARK: - Properties

        private let viewModel: DAppContainerViewModelType

        // MARK: - Subviews

        private lazy var webView = WKWebView(frame: .zero, configuration: viewModel.getWebviewConfiguration())

        // MARK: - Initializer

        init(viewModel: DAppContainerViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }

        // MARK: - Methods

        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            load()
        }

        // MARK: - Layout

        private func layout() {
            let reloadButton = UILabel(text: "Reload")
            addSubview(reloadButton)
            reloadButton.onTap(self, action: #selector(reload))
            reloadButton.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

            addSubview(webView)
            webView.backgroundColor = .blue
            webView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
            webView.autoPinEdge(.top, to: .bottom, of: reloadButton)
        }

        private func bind() {}

        // MARK: - Actions

        @objc private func reload() {
            load()
        }

        private func load() {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                }
            }

            webView.load(URLRequest(url: URL(string: viewModel.getDAppURL())!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
        }
    }
}
