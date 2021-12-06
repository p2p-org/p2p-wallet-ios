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
    func signTransaction(transaction: SolanaSDK.Transaction) -> Single<SolanaSDK.Transaction>
    func signTransactions(transactions: [SolanaSDK.Transaction]) -> Single<[SolanaSDK.Transaction]>
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
            print("window.P2PWalletOutgoingChannel.accept(\"\(message)\")")
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
            do {
                guard let rawData = body["args"] as? String,
                      let data = Data(base64urlEncoded: rawData) else {
                    call(webView: webView, id: id, error: DAppChannelError.invalidTransaction.localizedDescription)
                    return
                }
                
                let transaction = try SolanaSDK.Transaction.from(data: data)
                delegate.signTransaction(transaction: transaction).subscribe(onSuccess: { [weak self] trx in
                    do {
                        var trx = trx
                        self?.call(webView: webView, id: id, args: try trx.serialize().base64urlEncodedString())
                    } catch let e {
                        print(e)
                        self?.call(webView: webView, id: id, error: e.localizedDescription)
                    }
                }).disposed(by: disposeBag)
            } catch let error {
                call(webView: webView, id: id, error: error.localizedDescription)
            }
        case "signTransactions":
            guard let data = body["args"] as? [String] else {
                call(webView: webView, id: id, error: DAppChannelError.invalidTransaction.localizedDescription)
                return
            }
            
            do {
                var transactions = try data.map { try SolanaSDK.Transaction.from(data: Data(base64urlEncoded: $0)!) }
                delegate.signTransactions(transactions: transactions).subscribe(onSuccess: { [weak self] values in
                    do {
                        self?.call(webView: webView, id: id, args: try values.map { trx in
                            var trx = trx
                            try trx.serialize().base64urlEncodedString()
                        })
                    } catch let e {
                        self?.call(webView: webView, id: id, error: e.localizedDescription)
                    }
                }).disposed(by: disposeBag)
            } catch let e {
                call(webView: webView, id: id, error: e.localizedDescription)
            }
        
        default:
            call(webView: webView, id: id, error: "Invalid method call")
        }
    }
}

extension Encodable {
    func encoded(encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(self) // encodable is used here as self conforming protocol, concrete type isn't known
    }
}
