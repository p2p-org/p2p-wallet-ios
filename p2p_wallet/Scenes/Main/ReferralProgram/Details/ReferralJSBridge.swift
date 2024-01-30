import Combine
import Foundation
import Network
import Resolver
import WebKit

private enum ReferralJSBridgeMethod: String {
    case showShareDialog
    case nativeLog
    case signTransaction
    case getUserPublicKey
}

protocol ReferralBridge {
    var sharePublisher: AnyPublisher<String, Never> { get }
}

final class ReferralJSBridge: NSObject, ReferralBridge {
    var sharePublisher: AnyPublisher<String, Never> { shareSubject.eraseToAnyPublisher() }

    // MARK: - Dependencies

    private var logger = DefaultLogManager.shared
    @Injected private var userWalletManager: UserWalletManager
    @Injected private var nameStorage: NameStorageType

    // MARK: - Properties

    private let shareSubject = PassthroughSubject<String, Never>()

    private var subscriptions: [AnyCancellable] = []
    private weak var webView: WKWebView?

    private var address: String?
    private var domainName: String?

    public init(webView: WKWebView) {
        self.webView = webView
        super.init()

        userWalletManager.$wallet
            .map { $0?.account.publicKey.base58EncodedString }
            .assignWeak(to: \.address, on: self)
            .store(in: &subscriptions)

        domainName = nameStorage.getName()
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
              let method = ReferralJSBridgeMethod(rawValue: methodRaw)
        else {
            replyHandler(true, nil)
            return
        }

        // Overload reply handler
        let handler: (Any?, String?) -> Void = { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.logger.log(event: "ReferralProgramLog", data: String(describing: error), logLevel: LogLevel.error)
            } else {
                self.logger.log(event: "ReferralProgramLog", data: String(describing: result), logLevel: LogLevel.info)
            }

            replyHandler(result, nil)
        }

        switch method {
        case .showShareDialog:
            if let link = dict["link"] as? String {
                shareSubject.send(link)
                handler(link, nil)
            } else {
                handler(nil, "Empty link")
            }

        case .nativeLog:
            if let info = dict["info"] as? String {
                debugPrint(info)
                handler(info, nil)
            } else {
                handler(nil, "Empty info")
            }

        case .signTransaction:
            if let message = dict["message"] as? String {
                Task {
                    // TODO: https://linear.app/etherean/issue/ETH-806/[ios]-podpis-zaprosov-privatnym-klyuchom
                    handler(message, nil)
                }
            }

        case .getUserPublicKey:
            if let address {
                handler(address, nil)
            } else {
                handler(nil, "Empty address")
            }
        }
    }
}
