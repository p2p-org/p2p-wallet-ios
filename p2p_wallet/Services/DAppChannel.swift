//
//  DAppChannel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Foundation
import WebKit
import RxSwift

protocol DAppChannelDelegate: AnyObject {
    func connect() -> Single<String>
    func signTransaction() -> Single<String>
    func signTransactions() -> Single<[String]>
}

protocol DAppChannelType {
    func getWebviewConfiguration() -> WKWebViewConfiguration
    func setDelegate(_ delegate: DAppChannelDelegate)
}

// await window.webkit.messageHandlers.P2PWalletApi.postMessage({method: "connect"})

class DAppChannel: NSObject {
    // MARK: - Properties
    private weak var delegate: DAppChannelDelegate?
    private let disposeBag = DisposeBag()
}

extension DAppChannel: DAppChannelType {
    func getWebviewConfiguration() -> WKWebViewConfiguration {
        // configure target
        let targetInjection = WKUserScript(source: "window.p2pTarget = \"ios\"", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        
        // set config
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(targetInjection)
        config.userContentController.add(self, contentWorld: .page, name: "P2PWalletIncomingChannel")
        return config
    }
    
    func setDelegate(_ delegate: DAppChannelDelegate) {
        self.delegate = delegate
    }
    
    func call(webView: WKWebView, id: String, args: Any) {
        do {
            let message = try createMessage(id: id, method: nil, args: args)
            print("window.P2PWalletOutgoingChannel(\"\(message)\")")
            webView.evaluateJavaScript("window.P2PWalletOutgoingChannel.accept(\"\(message)\")", completionHandler: { result, error in
                print(result)
                print(error)
            })
        } catch let error {
            call(webView: webView, id: id, error: "Can not encode arguments.")
        }
    }
    
    func call(webView: WKWebView, id: String, error: String) {
        let message = try? createMessage(id: id, method: "error", args: error) ?? "{}"
        webView.evaluateJavaScript("window.P2PWalletOutgoingChannel.accept(\"\(message)\")")
    }
    
    func createMessage(id: String, method: String?, args: Any) throws -> String {
        let message = [
            "id": id,
            "method": method,
            "args": args
        ]
        return (try JSONSerialization.data(withJSONObject: message)).base64EncodedString(options: .endLineWithLineFeed)
    }
}

extension DAppChannel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let webView = message.webView,
              let body = message.body as? [String: Any],
              let id = body["id"] as? String else { return }
        
        guard let delegate = delegate else {
            call(webView: webView, id: id, error: "Platform is not ready")
            return
        }
        
        let method = body["method"] as? String
        
        switch method {
        case "connect":
            delegate.connect().subscribe(onSuccess: { [weak self] value in self?.call(webView: webView, id: id, args: value) }).disposed(by: disposeBag)
        case "signTransaction":
            delegate.signTransaction().subscribe(onSuccess: { [weak self] value in self?.call(webView: webView, id: id, args: value) }).disposed(by: disposeBag)
        case "signTransactions":
            delegate.signTransactions().subscribe(onSuccess: { [weak self]value in self?.call(webView: webView, id: id, args: value) }).disposed(by: disposeBag)
        default:
            call(webView: webView, id: id, error: "Invalid method call")
        }
    }
}
