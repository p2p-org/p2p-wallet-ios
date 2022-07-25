//
//  CreateOrRestoreWallet.IntroPlayerView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/02/2022.
//

import AVFoundation
import Foundation
import UIKit

extension CreateOrRestoreWallet {
    final class IntroPlayerView: UIView {
        // MARK: - Override default layer

        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        private var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        private var player: AVPlayer! {
            playerLayer.player
        }

        private var currentItem: AVPlayerItem {
            .init(url: Bundle.main.url(forResource: "onboarding_0\(step)_" + theme, withExtension: "mp4")!)
        }

        // MARK: - Properties

        private lazy var placeholderImageView = UIImageView(image: .onboardingLastFrame)

        public var skip: Bool = false
        private let theme: String
        private var step = 1
        private var movingToNextStep = false
        var completion: (() -> Void)?
        private var isAnimating = false
        private var isFinished = false
        private var activeResigned = false

        init(userInterfaceStyle: UIUserInterfaceStyle) {
            theme = userInterfaceStyle == .dark ? "b" : "w"

            super.init(frame: .zero)
            configureForAutoLayout()
            addSubview(placeholderImageView)
            placeholderImageView.autoPinEdgesToSuperviewEdges()
            placeholderImageView.isHidden = true

            playerLayer.player = AVPlayer(playerItem: currentItem)
            bind()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Methods

        private func bind() {
            NotificationCenter.default
                .addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
                    guard let self = self else { return }
                    switch self.step {
                    case 1:
                        if !self.movingToNextStep {
                            self.player.seek(to: .zero)
                            self.player.play()
                        } else {
                            self.step += 1

                            // show placeholder to fix slashing problem when changing video file
                            self.placeholderImageView.isHidden = false
                            self.setNeedsDisplay()

                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }

                                // replace video file
                                self.player.replaceCurrentItem(with: self.currentItem)
                                self.player.rate = 1
                                self.movingToNextStep = false
                                self.player.play()

                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                                    self?.placeholderImageView.isHidden = true
                                }
                            }
                        }
                    case 2:
                        self.completion?()
                        self.isFinished = true
                        self.isAnimating = false
                    default:
                        return
                    }
                }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(_appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }

        func resume() {
            if !player.isPlaying, step < 2 {
                player.seek(to: .zero)
                player.play()
            }
        }

        func playNext() {
            if skip {
                completion?()
                return
            }

            guard !isAnimating else { return }
            guard step < 2 else {
                completion?()
                isAnimating = false
                isFinished = true
                return
            }
            isAnimating = true
            player.rate = 2
            movingToNextStep = true
        }

        @objc private func appWillResignActive() {
            activeResigned = true
        }

        @objc private func _appDidBecomeActive() {
            guard activeResigned, !isFinished else { return }
            player.play()
        }
    }
}

private extension AVPlayer {
    var isPlaying: Bool {
        rate != 0 && error == nil
    }
}
