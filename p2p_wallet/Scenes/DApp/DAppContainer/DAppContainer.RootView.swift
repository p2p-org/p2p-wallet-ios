//
//  DAppContainer.RootView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import UIKit
import RxSwift
import WebKit

extension DAppContainer {
    class RootView: BEView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        @Injected private var viewModel: DAppContainerViewModelType
        
        // MARK: - Subviews
        private lazy var webView = WKWebView(frame: .zero, configuration: viewModel.getWebviewConfiguration())
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            webView.load(URLRequest(url: URL(string: "https://web.beardict.net/dapp/")!))
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
        
        private func bind() {
            
        }
        
        // MARK: - Actions
        @objc private func reload() {
            print("reload")
            webView.load(URLRequest(url: URL(string: "https://web.beardict.net/dapp/")!))
        }
        
        @objc private func showDetail() {
        }
    }
}
