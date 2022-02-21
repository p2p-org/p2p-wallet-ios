//
//  TransakViewController.swift
//  FBSnapshotTestCase
//
//  Created by Chung Tran on 27/07/2021.
//

import WebKit

public protocol BuyTokenWidgetLoadingView: UIView {
    func startLoading()
    func stopLoading()
}

extension UIActivityIndicatorView: BuyTokenWidgetLoadingView {
    public func startLoading() {
        startAnimating()
    }
    public func stopLoading() {
        stopAnimating()
    }
}

open class BuyTokenWidgetViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    // MARK: - Properties
    var loadsCount = 0
    let provider: Buy.ProcessingService

    // MARK: - Initializers
    init(provider: Buy.ProcessingService, loadingView: BuyTokenWidgetLoadingView = UIActivityIndicatorView()) {
        self.provider = provider
        self.loadingView = loadingView
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Subviews
    let loadingView: BuyTokenWidgetLoadingView
    lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
        // add loader
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadTransak()
        }
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadsCount += 1
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadsCount -= 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.loadsCount == 0 {
                self?.stopLoading()
            }
        }
    }
    
    // MARK: - Actions
    private func loadTransak() {
        // modify params
        let urlString = provider.getUrl()
        print(urlString)

        // load url
        guard let myURL = URL(string: urlString) else {
            let alert = UIAlertController(title: "Invalid URL", message: "The url isn't valid \(urlString)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        startLoading()
        
        // load url
        let myRequest = URLRequest(url: myURL)
        webView.load(myRequest)
    }
    
    // MARK: - Loading view
    private func startLoading() {
        loadingView.isHidden = false
        loadingView.startLoading()
    }
    
    private func stopLoading() {
        loadingView.isHidden = true
        loadingView.stopLoading()
    }
}
