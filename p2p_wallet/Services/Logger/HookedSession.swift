// import Foundation
// import SolanaSwift
//
// protocol RequestInterceptor {
//    var logger: LogManager { get set }
//    var baseURLs: [String] { get set }
// }
//
// @objc public class CustomURLProtocolRequestInterceptor: NSObject, RequestInterceptor {
//    var logger: LogManager
//    var baseURLs: [String]
//
//    init(logger: LogManager, urls: [String]) {
//        self.logger = logger
//        baseURLs = urls
//    }
//
//    func swizzleProtocolClasses() {
//        let instance = URLSessionConfiguration.default
//        let URLSessionConfigurationClass: AnyClass = object_getClass(instance)!
//
//        let method1: Method = class_getInstanceMethod(
//            URLSessionConfigurationClass,
//            #selector(getter: URLSessionConfigurationClass.protocolClasses)
//        )!
//        let method2: Method = class_getInstanceMethod(
//            URLSessionConfiguration.self,
//            #selector(URLSessionConfiguration.swizzle_protocolClasses)
//        )!
//
//        method_exchangeImplementations(method1, method2)
//    }
//
//    public func startRecording() {
//        URLProtocol.registerClass(CustormUrlProtocol.self)
//        swizzleProtocolClasses()
//    }
//
//    public func stopRecording() {
//        URLProtocol.unregisterClass(CustormUrlProtocol.self)
//        swizzleProtocolClasses()
//    }
// }
//
// extension URLSessionConfiguration {
//    @objc func swizzle_protocolClasses() -> [AnyClass]? {
//        var originalProtocolClasses = swizzle_protocolClasses()
//        if let doesContain = originalProtocolClasses?.contains(where: { protocolClass in
//            protocolClass == CustormUrlProtocol.self
//        }), !doesContain {
//            originalProtocolClasses?.insert(CustormUrlProtocol.self, at: 0)
//        }
//        return originalProtocolClasses
//    }
// }
//
// protocol URLProtocolLogger {
//    var supportedURLs: [String] { get set }
//    var logger: LogManager? { get set }
// }
//
// class CustormUrlProtocol: URLProtocol, URLProtocolLogger {
//    enum Constants {
//        static let RequestHandledKey = "URLProtocolRequestHandled"
//    }
//
//    var supportedURLs: [String] = [
//        "p2p.rpcpool.com",
//        "solana-api.projectserum.com",
//        "api.mainnet-beta.solana.com",
//        "api.testnet.solana.com",
//        "api.devnet.solana.com",
//        String.secretConfig("FEE_RELAYER_ENDPOINT")!,
//        String.secretConfig("NAME_SERVICE_ENDPOINT")!,
//    ]
//    var logger: LogManager? = DefaultLogManager.shared
//    var session: URLSession?
//    var sessionTask: URLSessionDataTask?
////    var currentRequest: RequestModel?
//
//    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
//        super.init(request: request, cachedResponse: cachedResponse, client: client)
//
//        if session == nil {
//            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        }
//    }
//
//    override public class func canInit(with request: URLRequest) -> Bool {
//        if CustormUrlProtocol.property(forKey: Constants.RequestHandledKey, in: request) != nil {
//            return false
//        }
//        return true
//    }
//
//    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
//        request
//    }
//
//    override public func startLoading() {
//        let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
//        CustormUrlProtocol.setProperty(true, forKey: Constants.RequestHandledKey, in: newRequest)
//        sessionTask = session?.dataTask(with: newRequest as URLRequest)
//        sessionTask?.resume()
////        currentRequest = RequestModel(request: request)
//    }
//
//    override public func stopLoading() {
//        sessionTask?.cancel()
////        currentRequest?.httpBody = body(from: request)
////        if let startDate = currentRequest?.date {
////            currentRequest?
////                .duration = fabs(startDate.timeIntervalSinceNow) * 1000 // Find elapsed time and convert to milliseconds
////        }
//
////        NetworkInterceptor.shared.logRequest(urlRequest: currentRequest!)
//    }
//
//    private func body(from request: URLRequest) -> Data? {
//        request.httpBody ?? request.httpBodyStream.flatMap { stream in
//            let data = NSMutableData()
//            stream.open()
//            while stream.hasBytesAvailable {
//                var buffer = [UInt8](repeating: 0, count: 1024)
//                let length = stream.read(&buffer, maxLength: buffer.count)
//                data.append(buffer, length: length)
//            }
//            stream.close()
//            return data as Data
//        }
//    }
// }
//
// extension CustormUrlProtocol: URLSessionDataDelegate {
//    public func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
//        client?.urlProtocol(self, didLoad: data)
//        debugPrint("*****" + String(data: data, encoding: .utf8))
//
////        if currentRequest?.dataResponse == nil {
////            currentRequest?.dataResponse = data
////        } else {
////            currentRequest?.dataResponse?.append(data)
////        }
//    }
//
//    public func urlSession(
//        _: URLSession,
//        dataTask _: URLSessionDataTask,
//        didReceive response: URLResponse,
//        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
//    ) {
//        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
//        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
////        currentRequest?.initResponse(response: response)
//        logger?.log(
//            event: "request: \(request.cURL())",
//            logLevel: .response,
//            data: String(data: request.httpBody ?? Data(), encoding: .utf8),
//            shouldLogEvent: {
//                let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)
//                guard let host = components?.host else { return false }
//                return supportedURLs.contains(host)
//            }
//        )
//
//        completionHandler(.allow)
//    }
//
//    public func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error {
////            currentRequest?.errorClientDescription = error.localizedDescription
//            logger?.log(
//                event: "request: \(request.cURL())",
//                logLevel: .error,
//                data: error.readableDescription,
//                shouldLogEvent: {
//                    let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)
//                    guard let host = components?.host else { return false }
//                    return supportedURLs.contains(host)
//                }
//            )
//            client?.urlProtocol(self, didFailWithError: error)
//        } else {
//            client?.urlProtocolDidFinishLoading(self)
//        }
//    }
//
//    public func urlSession(
//        _: URLSession,
//        task _: URLSessionTask,
//        willPerformHTTPRedirection response: HTTPURLResponse,
//        newRequest request: URLRequest,
//        completionHandler: @escaping (URLRequest?) -> Void
//    ) {
//        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
//        completionHandler(request)
//    }
//
//    public func urlSession(_: URLSession, didBecomeInvalidWithError error: Error?) {
//        guard let error = error else { return }
////        currentRequest?.errorClientDescription = error.localizedDescription
//        logger?.log(
//            event: "request: \(request.cURL())",
//            logLevel: .response,
//            data: error.readableDescription,
//            shouldLogEvent: {
//                let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)
//                guard let host = components?.host else { return false }
//                return supportedURLs.contains(host)
//            }
//        )
//        client?.urlProtocol(self, didFailWithError: error)
//    }
//
//    public func urlSession(
//        _: URLSession,
//        didReceive challenge: URLAuthenticationChallenge,
//        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
//    ) {
//        let protectionSpace = challenge.protectionSpace
//        let sender = challenge.sender
//
//        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//            if let serverTrust = protectionSpace.serverTrust {
//                let credential = URLCredential(trust: serverTrust)
//                sender?.use(credential, for: challenge)
//                completionHandler(.useCredential, credential)
//                return
//            }
//        }
//    }
//
//    public func urlSessionDidFinishEvents(forBackgroundURLSession _: URLSession) {
//        client?.urlProtocolDidFinishLoading(self)
//    }
// }
//
// struct RequestModel {
//    var date: Date?
//    var errorClientDescription: String?
//    var dataResponse: Data?
//    var httpBody: Data?
//    var duration: Double?
//    var response: URLResponse?
//    var request: URLRequest?
//
//    init(request: URLRequest) {
//        self.request = request
//    }
//
//    mutating func initResponse(response: URLResponse) {
//        self.response = response
//    }
// }
