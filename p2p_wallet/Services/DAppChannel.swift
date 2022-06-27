//
//  DAppChannel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Foundation
import RxSwift
import SolanaSwift
import WebKit

protocol DAppChannelDelegate: AnyObject {
    func connect() -> Single<String>
    func signTransaction(transaction: Transaction) -> Single<Transaction>
    func signTransactions(transactions: [Transaction]) -> Single<[Transaction]>
}

protocol DAppChannelType {
    func getWebviewConfiguration() -> WKWebViewConfiguration
    func setDelegate(_ delegate: DAppChannelDelegate)
}

class DAppChannel: NSObject {
    struct Message {
        let id: String
        let method: String?
        let args: Any

        func toBase64() throws -> String {
            let message: [String: Any?] = [
                "id": id,
                "method": method,
                "args": args,
            ]
            return (try JSONSerialization.data(withJSONObject: message))
                .base64EncodedString(options: .endLineWithLineFeed)
        }
    }

    // MARK: - Properties

    private weak var delegate: DAppChannelDelegate?
    private let disposeBag = DisposeBag()

    func setDelegate(_ delegate: DAppChannelDelegate) {
        self.delegate = delegate
    }

    func call(webView: WKWebView, id: String, args: Any) {
        do {
            let message = try Message(id: id, method: nil, args: args).toBase64()
            webView.evaluateJavaScript(sendingChannel(base64EncodedMessage: message))
        } catch {
            call(webView: webView, id: id, error: error.localizedDescription)
        }
    }

    func call(webView: WKWebView, id: String, error: String) {
        do {
            let message = try Message(id: id, method: "error", args: error).toBase64()
            webView.evaluateJavaScript(sendingChannel(base64EncodedMessage: message))
        } catch let e {
            debugPrint(e)
        }
    }

    func sendingChannel(base64EncodedMessage: String) -> String {
        "window.P2PWalletOutgoingChannel.accept(\"\(base64EncodedMessage)\")"
    }
}

extension DAppChannel: DAppChannelType {
    func getWebviewConfiguration() -> WKWebViewConfiguration {
        // configure target
        let targetInjection = WKUserScript(
            source: "window.p2pTarget = \"ios\"",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )

        // set config
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(targetInjection)
        config.userContentController.add(self, name: "P2PWalletIncomingChannel")
        return config
    }
}

extension DAppChannel: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
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
            delegate.connect().subscribe(onSuccess: { [weak self] value in
                self?.call(webView: webView, id: id, args: value)
            }).disposed(by: disposeBag)
        case "signTransaction":
            do {
                guard let rawData = body["args"] as? String,
                      let data = Data(base64urlEncoded: rawData)
                else {
                    call(webView: webView, id: id, error: DAppChannelError.invalidTransaction.localizedDescription)
                    return
                }

                let transaction = try Transaction.from(data: data)
                delegate.signTransaction(transaction: transaction).subscribe(onSuccess: { [weak self] trx in
                    do {
                        var trx = trx
                        self?.call(webView: webView, id: id, args: try trx.serialize().base64EncodedString())
                    } catch let e {
                        self?.call(webView: webView, id: id, error: e.localizedDescription)
                    }
                }).disposed(by: disposeBag)
            } catch {
                call(webView: webView, id: id, error: error.localizedDescription)
            }
        case "signTransactions":
            guard let data = body["args"] as? [String] else {
                call(webView: webView, id: id, error: DAppChannelError.invalidTransaction.localizedDescription)
                return
            }

            do {
                let transactions = try data.map { try Transaction.from(data: Data(base64urlEncoded: $0)!) }
                delegate.signTransactions(transactions: transactions).subscribe(onSuccess: { [weak self] values in
                    do {
                        self?.call(webView: webView, id: id, args: try values.map { trx -> String in
                            var trx = trx
                            return try trx.serialize().base64EncodedString()
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
