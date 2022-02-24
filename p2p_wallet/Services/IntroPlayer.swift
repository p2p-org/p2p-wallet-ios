//
//  IntroPlayer.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/02/2022.
//

import Foundation
import AVFoundation

enum IntroPlayerTheme: String {
    case w, b
}

protocol IntroPlayerType {
    init(theme: IntroPlayerTheme)
    func setTheme(_ theme: IntroPlayerTheme)
    func createLayer() -> CALayer
    func resume()
    func play()
}

class IntroPlayer: IntroPlayerType {
    private var theme: IntroPlayerTheme
    private var step = 1
    private var videoName: String {
        "onboarding_0\(step)_" + theme.rawValue
    }
    private lazy var player = AVPlayer(playerItem: nil)
    
    required init(theme: IntroPlayerTheme) {
        self.theme = theme
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
            self?.play()
        }
    }
    
    func setTheme(_ theme: IntroPlayerTheme) {
        self.theme = theme
    }
    
    func createLayer() -> CALayer {
        AVPlayerLayer(player: player)
    }
    
    func resume() {
        if !player.isPlaying {
            play()
        }
    }
    
    func play() {
        player.replaceCurrentItem(with: .init(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!))
        player.seek(to: .zero)
        player.play()
    }
}

private extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
