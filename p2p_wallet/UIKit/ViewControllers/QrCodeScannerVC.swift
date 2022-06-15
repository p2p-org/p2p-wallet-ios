//
//  QrCodeScannerVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import AnalyticsManager
import AVFoundation
import Foundation
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
    private lazy var closeButton = UIButton.closeFill()
        .onTap(self, action: #selector(closeButtonDidTouch))

    override func setUp() {
        super.setUp()
        view.backgroundColor = .black

        view.addSubview(cameraContainerView)
        cameraContainerView.autoPinEdgesToSuperviewSafeArea(with: .init(x: 0, y: 44))

        cameraContainerView.addSubview(rangeImageView)
        rangeImageView.autoCenterInSuperview()

        rangeImageView.addSubview(overlayLayer)
        overlayLayer.autoPinEdgesToSuperviewEdges(with: .init(all: 10))

        cameraContainerView.addSubview(rangeLabel)
        rangeLabel.autoCenterInSuperview()

        cameraContainerView.addSubview(closeButton)
        closeButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 16)

        view.layoutIfNeeded()

        setUpCamera()
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
            analyticsManager.log(event: .scanQrSuccess)
            back()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        debugPrint(code)
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @objc func closeButtonDidTouch() {
        analyticsManager.log(event: .scanQrClose)
        back()
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
    func setUpCamera() {
        // camera unavailable
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            handleCameraUnavailable()
            return
        }

        // request camera authorization
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async { [weak self] in
                    self?.handleCameraAuthrizationGranted(granted)
                }
            })
            return
        }

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
        previewLayer.videoGravity = .resizeAspectFill

        cameraContainerView.layer.addSublayer(previewLayer)
        captureSession.startRunning()

        // bring important subviews to front
        cameraContainerView.bringSubviewToFront(rangeImageView)
        cameraContainerView.bringSubviewToFront(rangeLabel)
        cameraContainerView.bringSubviewToFront(closeButton)
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

    private func handleCameraAuthrizationGranted(_ granted: Bool) {
        if granted {
            setUpCamera()
        } else {
            showAlert(
                title: L10n.changeYourSettingsToUseCameraForScanningQrCode,
                message: L10n.ThisAppDoesNotHavePermissionToUseYourCameraForScanningQrCode.pleaseEnableItInSettings,
                buttonTitles: [L10n.ok, L10n.cancel],
                highlightedButtonIndex: 0
            ) { [weak self] index in
                if index == 0 {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { success in
                            debugPrint("Settings opened: \(success)") // Prints true
                        })
                    }
                } else {
                    self?.back()
                }
            }
        }
    }
}
