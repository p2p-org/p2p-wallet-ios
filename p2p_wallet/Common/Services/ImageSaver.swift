//
//  ImageSaver.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 11.02.2022.
//

import Photos

protocol ImageSaverType: AnyObject {
    func save(image: UIImage, resultHandler: ((Result<Void, ImageSaver.Error>) -> Void)?)
}

final class ImageSaver: NSObject, ImageSaverType {
    enum Error: Swift.Error {
        case noAccess
        case restrictedRightNow
        case unknown(Swift.Error)
    }

    private var resultHandler: ((Result<Void, ImageSaver.Error>) -> Void)?
    private var oldStatus: PHAuthorizationStatus?

    func save(
        image: UIImage,
        resultHandler: ((Result<Void, ImageSaver.Error>) -> Void)?
    ) {
        self.resultHandler = resultHandler

        oldStatus = getLibraryStatus()

        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImageCallback), nil)
    }

    @objc
    func saveImageCallback(
        _: UIImage,
        didFinishSavingWithError error: Swift.Error?,
        contextInfo _: UnsafeRawPointer
    ) {
        if let error = error {
            handlePhotoLibrary(error: error)
        } else {
            resultHandler?(.success(()))
        }
    }

    private func handlePhotoLibrary(error: Swift.Error) {
        switch getLibraryStatus() {
        case .authorized, .notDetermined:
            resultHandler?(.failure(.unknown(error)))
        case .denied, .restricted, .limited:
            if oldStatus == .notDetermined {
                resultHandler?(.failure(.restrictedRightNow))
            } else {
                resultHandler?(.failure(.noAccess))
            }
        @unknown default:
            resultHandler?(.failure(.unknown(error)))
        }
    }

    private func getLibraryStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
}
