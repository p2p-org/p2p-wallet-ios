//
//  MainViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/02/2021.
//

import Foundation
import UIKit
import Action

protocol _MainScenesFactory {
    func makeTabBarVC() -> TabBarVC
}

class MainViewController: BaseVC {
    // MARK: - Dependencies
    @Injected private var viewModel: MainViewModelType
    
    // MARK: - Properties
    private let scenesFactory: _MainScenesFactory
    private let authenticateWhenAppears: Bool
    
    // MARK: - Subviews
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        return blurEffectView
    }()
    private var localAuthVC: Authentication.ViewController?
    
    // MARK: - Initializer
    init(scenesFactory: _MainScenesFactory, authenticateWhenAppears: Bool)
    {
        self.scenesFactory = scenesFactory
        self.authenticateWhenAppears = authenticateWhenAppears
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if authenticateWhenAppears {
            viewModel.authenticate(presentationStyle: .login())
        }
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        add(child: scenesFactory.makeTabBarVC())
        view.addSubview(blurEffectView)
        blurEffectView.autoPinEdgesToSuperviewEdges()
    }
    
    override func bind() {
        super.bind()
        // authentication status
        viewModel.authenticationStatusDriver
            .drive(onNext: {[weak self] in self?.handleAuthenticationStatus($0)})
            .disposed(by: disposeBag)
        
        // blurEffectView
        viewModel.authenticationStatusDriver
            .map {$0 == nil}
            .drive(blurEffectView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func handleAuthenticationStatus(_ status: AuthenticationPresentationStyle?) {
        // dismiss
        guard let authStyle = status else {
            localAuthVC?.dismiss(animated: true) { [weak self] in
                self?.localAuthVC = nil
            }
            return
        }
        
        // clean
        localAuthVC?.dismiss(animated: false, completion: nil)
        localAuthVC = Authentication.ViewController()
        localAuthVC?.title = authStyle.title
        localAuthVC?.isIgnorable = !authStyle.isRequired
        localAuthVC?.useBiometry = authStyle.useBiometry
        
        if authStyle.isFullScreen {
            localAuthVC?.modalPresentationStyle = .fullScreen
        }
        
        // completion
        localAuthVC?.onSuccess = {[weak self] in
            self?.viewModel.authenticate(presentationStyle: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authStyle.completion?()
            }
        }
        
        // cancelledCompletion
        if !authStyle.isRequired {
            // disable swipe down
            localAuthVC?.isModalInPresentation = true
            
            // handle cancelled by tapping <x>
            localAuthVC?.onCancel = {[weak self] in
                self?.viewModel.authenticate(presentationStyle: nil)
            }
        }
        
        // present on top
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(localAuthVC!, animated: true, completion: nil)
        }
    }
}
