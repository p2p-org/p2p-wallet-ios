import Combine
import Foundation
import Network
import Resolver
import SolanaSwift
import TweetNacl
import WebKit

protocol ReferralBridge {
    var sharePublisher: AnyPublisher<String, Never> { get }
}

final class ReferralJSBridge: NSObject, ReferralBridge {
    var sharePublisher: AnyPublisher<String, Never> { shareSubject.eraseToAnyPublisher() }

    // MARK: - Dependencies

    private let logger = DefaultLogManager.shared
    @Injected private var userWalletManager: UserWalletManager

    // MARK: - Properties

    private let shareSubject = PassthroughSubject<String, Never>()
    private var subscriptions: [AnyCancellable] = []
    private weak var webView: WKWebView?

    public init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }

    func reload() {
        Task {
            await MainActor.run { webView?.reload() }
        }
    }

    func loadScript(name: String) -> String? {
        guard let path = Bundle.main.path(forResource: name, ofType: "js") else { return nil }
        do {
            return try String(contentsOfFile: path)
        } catch {
            return nil
        }
    }

    public func inject() {
        guard let bridgeScript = loadScript(name: "ReferralBridge") else {
            debugPrint("Inject provider failure")
            return
        }

        guard let contentController = webView?.configuration.userContentController else { return }
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: "request")

        let script = WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script)
    }
}

extension ReferralJSBridge: WKScriptMessageHandlerWithReply {
    public func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        guard let dict = message.body as? [String: AnyObject] else {
            replyHandler(true, "Error")
            return
        }

        guard let methodRaw = dict["method"] as? String,
              let method = ReferralBridgeMethod(rawValue: methodRaw)
        else {
            replyHandler(true, nil)
            return
        }

        // Overload reply handler
        let handler: (String?, ReferralBridgeError?) -> Void = { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.logger.log(event: "ReferralProgramLog", data: String(describing: result), logLevel: LogLevel.info)
                replyHandler(result, nil)
            } else {
                self.logger.log(
                    event: "ReferralProgramLog",
                    data: String(describing: error?.rawValue),
                    logLevel: LogLevel.error
                )
                replyHandler(nil, error?.rawValue)
            }
        }

        guard let user = userWalletManager.wallet else {
            handler(nil, .emptyAddress)
            return
        }

        switch method {
        case .showShareDialog:
            if let link = dict["link"] as? String {
                shareSubject.send(link)
                handler(link, nil)
            } else {
                handler(nil, .emptyLink)
            }

        case .nativeLog:
            if let info = dict["info"] as? String {
                debugPrint(info)
                handler(info, nil)
            } else {
                handler(nil, .emptyLog)
            }

        case .signMessage:
            if let message = dict["message"] as? String,
               let user = userWalletManager.wallet,
               let base64Data = Data(base64Encoded: message, options: .ignoreUnknownCharacters)
            {
                Task {
                    do {
                        let signed = try SignMessageSignature(message: message)
                            .signAsBase64(secretKey: user.account.secretKey)
                        handler(signed, nil)
                    } catch {
                        handler(nil, .signFailed)
                    }
                }
            } else {
                handler(nil, .signFailed)
            }

        case .getUserPublicKey:
            handler(user.account.publicKey.base58EncodedString, nil)
        }
    }
}

struct SignMessageSignature: Codable, BorshSerializable {
    let message: String

    func serialize(to writer: inout Data) throws {
        try message.serialize(to: &writer)
    }

    func sign(secretKey: Data) throws -> Data {
        var data = Data()
        try serialize(to: &data)
        return try NaclSign.signDetached(message: data, secretKey: secretKey)
    }

    func signAsBase64(secretKey: Data) throws -> String {
        try sign(secretKey: secretKey).base64EncodedString()
    }
}
