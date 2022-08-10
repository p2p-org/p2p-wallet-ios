//
//  DAppChannel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Combine
import Foundation
import SolanaSwift
import WebKit

protocol DAppChannelDelegate: AnyObject {
    func connect() async throws -> String
    func signTransaction(transaction: Transaction) async throws -> Transaction
    func signTransactions(transactions: [Transaction]) async throws -> [Transaction]
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
    private var subscriptions = [AnyCancellable]()

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
            Task {
                let value = try await delegate.connect()
                call(webView: webView, id: id, args: value)
            }
        case "signTransaction":
            do {
                guard let rawData = body["args"] as? String,
                      let data = Data(base64urlEncoded: rawData)
                else {
                    call(webView: webView, id: id, error: DAppChannelError.invalidTransaction.localizedDescription)
                    return
                }

                let transaction = try Transaction.from(data: data)
                Task {
                    do {
                        var trx = try await delegate.signTransaction(transaction: transaction)
                        call(webView: webView, id: id, args: try trx.serialize().base64EncodedString())
                    } catch {
                        call(webView: webView, id: id, error: error.localizedDescription)
                    }
                }
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

                Task {
                    do {
                        let values = try await delegate.signTransactions(transactions: transactions)
                        call(webView: webView, id: id, args: try values.map { trx -> String in
                            var trx = trx
                            return try trx.serialize().base64EncodedString()
                        })
                    } catch {
                        call(webView: webView, id: id, error: error.localizedDescription)
                    }
                }
            } catch let e {
                call(webView: webView, id: id, error: e.localizedDescription)
            }

        default:
            call(webView: webView, id: id, error: "Invalid method call")
        }
    }
}
