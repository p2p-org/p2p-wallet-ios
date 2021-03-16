//
//  QrCodeScannerVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import AVFoundation
import UIKit

class QrCodeScannerVC: BaseVC {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let scanSize = CGSize(width: 200.0, height: 200.0)
    
    /// The callback for qr code recognizer, do any validation and return true if qr code valid
    var callback: ((String) -> Bool)?
    
    lazy var cameraContainerView = UIView(backgroundColor: .red, cornerRadius: 20)

    override func setUp() {
        super.setUp()
        
        view.backgroundColor = .black
        
        view.addSubview(cameraContainerView)
        cameraContainerView.autoPinEdgesToSuperviewSafeArea(with: .init(x: 0, y: 44))
        
        let rangeImageView = UIImageView(width: scanSize.width, height: scanSize.height, image: .qrCodeRange)
        cameraContainerView.addSubview(rangeImageView)
        rangeImageView.autoCenterInSuperview()
        
        let overlayLayer = UIView(backgroundColor: UIColor.black.withAlphaComponent(0.35), cornerRadius: 16)
        rangeImageView.addSubview(overlayLayer)
        overlayLayer.autoPinEdgesToSuperviewEdges(with: .init(all: 10))
        
        let rangeLabel = UILabel(text: L10n.scanQRCode, weight: .medium, textColor: .white, textAlignment: .center)
        cameraContainerView.addSubview(rangeLabel)
        rangeLabel.autoCenterInSuperview()
        
        let closeButton = UIButton.closeFill()
            .onTap(self, action: #selector(back))
        cameraContainerView.addSubview(closeButton)
        closeButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 16)
        
        view.layoutIfNeeded()
        
        setUpCamera()
        
        cameraContainerView.bringSubviewToFront(rangeImageView)
        cameraContainerView.bringSubviewToFront(rangeLabel)
        cameraContainerView.bringSubviewToFront(closeButton)
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
            captureSession.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            dismiss(animated: true)
        }
        print(code)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func back() {
        captureSession?.stopRunning()
        super.back()
    }
}

extension QrCodeScannerVC: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            found(code: stringValue)
        }
    }
}

extension QrCodeScannerVC {
    func setUpCamera() {
        if cameraAvailable,
           cameraAuthorized,
           let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        {
            captureSession = AVCaptureSession()

            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                failed()
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            let screenSize = UIScreen.main.bounds.size
            var scanRect = CGRect(x: (screenSize.width-scanSize.width)/2.0, y: (screenSize.height-scanSize.height)/2.0, width: scanSize.width, height: scanSize.height)
            
            scanRect = CGRect(x: scanRect.origin.y/screenSize.height, y: scanRect.origin.x/screenSize.width, width: scanRect.size.height/screenSize.height, height: scanRect.size.width/screenSize.width)
            
            metadataOutput.rectOfInterest = scanRect

            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                failed()
                return
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            
            cameraContainerView.layer.addSublayer(previewLayer)
            captureSession.startRunning()
        } else {
            failed()
        }
           
    }
    
    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private var cameraAuthorized: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied {
            showAlert(
                title: L10n.changeYourSettingsToUseCameraForScanningQrCode,
                message: L10n.ThisAppDoesNotHavePermissionToUseYourCameraForScanningQrCode.pleaseEnableItInSettings,
                buttonTitles: [L10n.ok, L10n.cancel],
                highlightedButtonIndex: 0)
            { (index) in
                if index == 0 {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                }
            }
            return false
        }
        return true
    }
    
    func failed() {
        let ac = UIAlertController(title: L10n.scanningQrCodeNotSupported, message: L10n.YourDeviceDoesNotSupportScanningACodeFromAnItem.pleaseUseADeviceWithACamera, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
}
