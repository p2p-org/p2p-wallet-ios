//
//  QrCodeScannerVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/4/20.
//

import Foundation
import AVFoundation
import UIKit

class QrCodeScannerVC: BaseVC, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    lazy var cameraContainerView = UIView(backgroundColor: .black)

    override func setUp() {
        super.setUp()
        
        view.addSubview(cameraContainerView)
        cameraContainerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let rangeImageView = UIImageView(width: 200, height: 200, image: .qrCodeRange)
        cameraContainerView.addSubview(rangeImageView)
        rangeImageView.autoCenterInSuperview()
        
        let rangeLabel = UILabel(text: L10n.scanQRCode, textSize: 15, weight: .medium, textColor: .white, textAlignment: .center)
        cameraContainerView.addSubview(rangeLabel)
        rangeLabel.autoCenterInSuperview()
        
        let closeButton = UIButton.close(tintColor: .white)
            .onTap(self, action: #selector(back))
        view.addSubview(closeButton)
        closeButton.autoPinToTopRightCornerOfSuperviewSafeArea(xInset: 20)
        
        let bottomView = UIView(backgroundColor: .background, cornerRadius: 16)
        view.addSubview(bottomView)
        bottomView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        bottomView.autoPinEdge(.top, to: .bottom, of: cameraContainerView, withOffset: -16)
        
        let stackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill)
        bottomView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(x: 16, y: 34))
        
        stackView.addArrangedSubview(UILabel(text: L10n.scanAnP2PAddress, textSize: 15, weight: .medium))
        
        view.layoutIfNeeded()
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
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
        
        cameraContainerView.bringSubviewToFront(rangeImageView)
        cameraContainerView.bringSubviewToFront(rangeLabel)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraContainerView.layer.bounds
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        print(code)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func back() {
        captureSession.stopRunning()
        super.back()
    }
}
