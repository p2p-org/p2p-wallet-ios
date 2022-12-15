import AnalyticsManager
import AVFoundation
import Foundation
import KeyAppUI
import PureLayout
import Resolver
import UIKit

class QrCodeScannerVC: BaseVC {
    // MARK: - Dependencies

    @Injected var analyticsManager: AnalyticsManager

    // MARK: - Properties

    var captureSession: AVCaptureSession!
    let scanSize = CGSize(width: 200.0, height: 200.0)

    /// The callback for qr code recognizer, do any validation and return true if qr code valid
    var callback: ((String) -> Bool)?

    // MARK: - Subviews and sublayers

    var previewLayer: AVCaptureVideoPreviewLayer!
    lazy var cameraContainerView = UIView(cornerRadius: 20)
    private lazy var rangeImageView = UIImageView(width: scanSize.width, height: scanSize.height, image: .qrCodeRange)
    private lazy var overlayLayer = UIView(backgroundColor: UIColor.black.withAlphaComponent(0.35), cornerRadius: 16)
    private lazy var rangeLabel = UILabel(
        text: L10n.scanQRCode,
        weight: .medium,
        textColor: .white,
        textAlignment: .center
    )
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(L10n.close, for: .normal)
        button.onTap(self, action: #selector(closeButtonDidTouch))
        button.titleLabel?.font = .font(of: .text1)
        return button
    }()

    private lazy var torchButton: UIButton = {
        let button = UIButton()
        button.setTitle(L10n.turnOnTheLight, for: .normal)
        button.titleLabel?.font = .font(of: .text2)
        button.onTap(self, action: #selector(torchButtonDidTouch))
        button.layer.cornerRadius = 28
        return button
    }()

    override func setUp() {
        super.setUp()
        view.backgroundColor = .black

        view.addSubview(cameraContainerView)
        cameraContainerView.autoPinEdge(toSuperviewEdge: .top, withInset: 0)
        cameraContainerView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0)
        cameraContainerView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0)
        cameraContainerView.autoPinEdge(toSuperviewEdge: .bottom, withInset: -cameraContainerView.bottomSafeInset)

        cameraContainerView.addSubview(rangeImageView)
        rangeImageView.autoCenterInSuperview()

        rangeImageView.addSubview(overlayLayer)
        overlayLayer.autoPinEdgesToSuperviewEdges(with: .init(all: 10))

        cameraContainerView.addSubview(rangeLabel)
        rangeLabel.autoCenterInSuperview()

        cameraContainerView.addSubview(closeButton)
        closeButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 16)

        cameraContainerView.addSubview(torchButton)
        torchButton.setTorchConstraints()

        view.layoutIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        Task {
            await requestPermission()
            setupCamera()
        }
    }

    @objc func appMovedToForeground() {
        if let device = AVCaptureDevice.default(for: .video), device.torchMode == .on {
            isTorchOn = device.torchMode == .on
        } else {
            isTorchOn = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraContainerView.layer.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession?.startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession?.stopRunning()
    }

    func found(code: String) {
        if callback?(code) == true {
            analyticsManager.log(event: AmplitudeEvent.scanQrSuccess)
            back()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        print(code)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @objc func closeButtonDidTouch() {
        analyticsManager.log(event: AmplitudeEvent.scanQrClose)
        back()
    }

    private var isTorchOn = false {
        didSet {
            if isTorchOn {
                torchButton.backgroundColor(color: Asset.Colors.snow.color)
                torchButton.setTitle(L10n.turnOffTheLight, for: .normal)
                torchButton.setTitleColor(Asset.Colors.night.color, for: .normal)
            } else {
                torchButton.backgroundColor(color: .clear)
                torchButton.setTitle(L10n.turnOnTheLight, for: .normal)
                torchButton.setTitleColor(Asset.Colors.snow.color, for: .normal)
            }
        }
    }

    @objc func torchButtonDidTouch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                    isTorchOn = true
                } catch {
                    DefaultLogManager.shared.log(event: "Can't toggle torch", logLevel: .debug)
                }
            }
            device.unlockForConfiguration()
        } catch {
            DefaultLogManager.shared.log(event: error.localizedDescription, logLevel: .debug)
        }
    }

    override func back() {
        captureSession?.stopRunning()
        super.back()
    }
}

extension QrCodeScannerVC: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from _: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            found(code: stringValue)
        }
    }
}

extension QrCodeScannerVC {
    func requestPermission() async {
        // camera unavailable
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            handleCameraUnavailable()
            return
        }

        // request camera authorization
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            let status = await AVCaptureDevice.requestAccess(for: .video)
            if !status { showPermissionErrorDialog() }
        }
    }

    private func handleCameraUnavailable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.captureSession = nil
            self?.showAlert(
                title: L10n.scanningQrCodeNotSupported,
                message: L10n.YourDeviceDoesNotSupportScanningACodeFromAnItem.pleaseUseADeviceWithACamera,
                buttonTitles: [L10n.ok]
            ) { [weak self] _ in
                self?.back()
            }
        }
    }

    private func handleCaptureSessionFailed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.captureSession = nil
            self?.showAlert(
                title: L10n.couldNotCreateCaptureSession,
                message: L10n.thereIsSomethingWrongWithYourCameraPleaseTryAgainLater,
                buttonTitles: [L10n.ok]
            ) { [weak self] _ in
                self?.back()
            }
        }
    }

    private func setupCamera() {
        // camera is authorized
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            handleCaptureSessionFailed()
            return
        }

        captureSession = AVCaptureSession()
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            handleCaptureSessionFailed()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            handleCaptureSessionFailed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        let screenSize = UIScreen.main.bounds.size
        var scanRect = CGRect(
            x: (screenSize.width - scanSize.width) / 2.0,
            y: (screenSize.height - scanSize.height) / 2.0,
            width: scanSize.width,
            height: scanSize.height
        )

        scanRect = CGRect(
            x: scanRect.origin.y / screenSize.height,
            y: scanRect.origin.x / screenSize.width,
            width: scanRect.size.height / screenSize.height,
            height: scanRect.size.width / screenSize.width
        )

        metadataOutput.rectOfInterest = scanRect

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            handleCaptureSessionFailed()
            return
        }

        // remove existing layer
        previewLayer?.removeFromSuperlayer()

        // create new layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraContainerView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill

        cameraContainerView.layer.addSublayer(previewLayer)
        captureSession.startRunning()

        // bring important subviews to front
        cameraContainerView.bringSubviewToFront(rangeImageView)
        cameraContainerView.bringSubviewToFront(rangeLabel)
        cameraContainerView.bringSubviewToFront(closeButton)
        cameraContainerView.bringSubviewToFront(torchButton)
    }

    private func showPermissionErrorDialog() {
        showAlert(
            title: L10n.unableToAccessCamera,
            message: L10n.KeyAppCannotScanQRCodesWithoutAccessToYourCamera.pleaseEnableAccessUnderPrivacySettings,
            buttonTitles: [L10n.ok, L10n.cancel],
            highlightedButtonIndex: 0
        ) { [weak self] index in
            if index == 0 {
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { success in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            } else {
                self?.back()
            }
        }
    }
}

private extension UIView {
    func setTorchConstraints() {
        superview?.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-40-[view]-40-|",
                options: [],
                metrics: nil,
                views: ["view": self]
            )
        )
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:[view(56)]",
                options: [],
                metrics: nil,
                views: ["view": self]
            )
        )
        autoPinEdge(toSuperviewEdge: .bottom, withInset: bottomSafeInset + 40)
    }

    var bottomSafeInset: CGFloat { UIApplication.shared.kWindow?.safeAreaInsets.bottom ?? 0 }
}
