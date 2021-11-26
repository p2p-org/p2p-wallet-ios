//
// Created by Giang Long Tran on 25.11.21.
//

import Foundation
import WebKit
import RxSwift

protocol DAppChannelDelegate: AnyObject {
    func connect() -> Single<String>
    func signTransaction() -> Single<String>
    func signTransactions() -> Single<[String]>
}

// await window.webkit.messageHandlers.P2PWalletApi.postMessage({method: "connect"})

protocol DAppChannel: AnyObject {
    func getWebviewConfiguration() -> WKWebViewConfiguration
    func setDelegate(_ delegate: DAppChannelDelegate)
}

extension DAppContainer {
    @available(iOS 14.0, *)
    class Channel: NSObject {
        // MARK: - Properties
        weak var delegate: DAppChannelDelegate?
        private let disposeBag = DisposeBag()
    }
}

extension DAppContainer.Channel: DAppChannel {
    func getWebviewConfiguration() -> WKWebViewConfiguration {
        // configure target
        let targetInjection = WKUserScript(source: "window.p2pTarget = \"ios\"", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        
        // set config
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(targetInjection)
        config.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "P2PWalletApi")
        return config
    }
    
    func setDelegate(_ delegate: DAppChannelDelegate) {
        self.delegate = delegate
    }
}

extension DAppContainer.Channel: WKScriptMessageHandlerWithReply, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let delegate = delegate else {
            replyHandler(nil, "Platform is not ready")
            return
        }
        
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else {
            replyHandler(nil, "Invalid method call")
            return
        }
        
        switch method {
        case "connect":
            delegate.connect().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
        case "signTransaction":
            delegate.signTransaction().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
        case "signTransactions":
            delegate.signTransactions().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
        default:
            replyHandler(nil, "Invalid method call")
        }
    }
}
