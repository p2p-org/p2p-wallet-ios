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

//await window.webkit.messageHandlers.P2PWalletApi.postMessage({method: "connect"})

extension DAppContainer {
    
    @available(iOS 14.0, *)
    class Channel: NSObject, WKScriptMessageHandlerWithReply, WKScriptMessageHandler {
        var webView: WKWebView!
        weak var delegate: DAppChannelDelegate?
        private let disposeBag = DisposeBag()
        
        override init() {
            super.init()
            
            let targetInjection = WKUserScript(source: "window.p2pTarget = \"ios\"", injectionTime: .atDocumentStart, forMainFrameOnly: true)
            
            let config = WKWebViewConfiguration()
            config.userContentController.addUserScript(targetInjection)
            config.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "P2PWalletApi")
            
            webView = WKWebView(frame: .zero, configuration: config)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> ()) {
            guard let delegate = delegate else {
                replyHandler(nil, "Platform is not ready")
                return
            }
            
            guard let body = message.body as? Dictionary<String, Any>,
                  let method = body["method"] as? String else {
                replyHandler(nil, "Invalid method call")
                return
            }
            
            switch (method) {
            case "connect":
                delegate.connect().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
                break
            case "signTransaction":
                delegate.signTransaction().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
                break
            case "signTransactions":
                delegate.signTransactions().subscribe(onSuccess: { value in replyHandler(value, nil) }).disposed(by: disposeBag)
                break
            default:
                replyHandler(nil, "Invalid method call")
            }
        }
    }
}
