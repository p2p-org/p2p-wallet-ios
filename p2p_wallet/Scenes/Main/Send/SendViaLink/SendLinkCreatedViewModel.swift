//
//  SendLinkCreatedViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 27.03.2023.
//

import AnalyticsManager
import Foundation
import Resolver
import Combine

final class SendLinkCreatedViewModel {
    
    // Dependencies
    @Injected private var notificationService: NotificationService
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var walletsRepository: WalletsRepository
    
    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let shareSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Coordinator Output
    
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var share: AnyPublisher<Void, Never> { shareSubject.eraseToAnyPublisher() }
    
    let link: String
    let formatedAmount: String
    
    // MARK: - Init
    
    init(
        link: String,
        formatedAmount: String
    ) {
        self.link = link
        self.formatedAmount = formatedAmount
    }
    
    // MARK: - View Output
    
    func copyClicked() {
        logCopyLink()
        
        let pasteboard = UIPasteboard.general
        pasteboard.string = link
        notificationService.showInAppNotification(.done(L10n.copied))
    }
    
    func closeClicked() {
        closeSubject.send()
    }
    
    func shareClicked() {
        logShareLink()
        shareSubject.send()
    }
    
    func onAppear() {
        logCreatingLinkEndScreenOpen()
    }
}

// MARK: - Analytics

private extension SendLinkCreatedViewModel {
    func logCreatingLinkEndScreenOpen() {
        guard
            let tokenName = formatedAmount.split(separator: " ").first,
            let tokenValue = formatedAmount.split(separator: " ").last,
            let tokenValue = Double(tokenValue),
            let pubkey = walletsRepository.nativeWallet?.pubkey
        else { return }
        
        analyticsManager.log(event: .sendCreatingLinkEndScreenOpen(
            tokenName: String(tokenName),
            tokenValue: tokenValue,
            pubkey: pubkey
        ))
    }
    
    func logShareLink() {
        analyticsManager.log(event: .sendClickShareLink)
    }
    
    func logCopyLink() {
        analyticsManager.log(event: .sendClickCopyLink)
    }
}
