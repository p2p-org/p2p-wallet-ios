//
//  WLPincodeVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation

class WLPincodeVC: BaseVC {
    // MARK: - Properties

    /// current pin code for confirming, if nil, the scene is create pincode
    private let currentPincode: String?
    override var title: String? {
        didSet {
            navigationBar.titleLabel.text = title
        }
    }

    // MARK: - Callback

    var onCreate: ((String) -> Void)?
    var onSuccess: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - Subviews

    private lazy var navigationBar = WLNavigationBar(forAutoLayout: ())
    private lazy var pincodeView = WLPinCodeView(correctPincode: currentPincode)

    // MARK: - Initializer

    init(currentPincode: String? = nil) {
        self.currentPincode = currentPincode
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: - Methods

    override func setUp() {
        super.setUp()
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

        if isConfirmingPincode() {
            navigationBar.backButton.onTap(self, action: #selector(back))
        } else {
            navigationBar.backButton.onTap(self, action: #selector(cancelOnboarding))
        }

        let pincodeWrapperView = UIView(forAutoLayout: ())
        view.addSubview(pincodeWrapperView)
        pincodeWrapperView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        pincodeWrapperView.autoPinEdge(.top, to: .bottom, of: navigationBar)

        pincodeWrapperView.addSubview(pincodeView)
        pincodeView.autoCenterInSuperview()

        pincodeView.onSuccess = { [weak self] pincode in
            guard let self = self, let pincode = pincode else { return }

            // confirm pincode scene
            if self.isConfirmingPincode() {
                self.onSuccess?(pincode)
            }

            // create pincode scene
            else {
                self.onCreate?(pincode)
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelOnboarding() {
        onCancel?()
    }

    // MARK: - Helpers

    private func isConfirmingPincode() -> Bool {
        currentPincode != nil
    }
}
