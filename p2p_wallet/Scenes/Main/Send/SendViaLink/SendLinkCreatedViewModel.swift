import AnalyticsManager
import Foundation
import Resolver
import Combine
import UIKit

final class SendLinkCreatedViewModel {
    
    // Dependencies
    @Injected private var notificationService: NotificationService
    @Injected private var analyticsManager: AnalyticsManager
    
    // Subjects
    private let closeSubject = PassthroughSubject<Void, Never>()
    private let shareSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Coordinator Output
    
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    var share: AnyPublisher<Void, Never> { shareSubject.eraseToAnyPublisher() }
    
    let link: String
    let formatedAmount: String
    private let intermediateAccountPubKey: String
    
    // MARK: - Init
    
    init(
        link: String,
        formatedAmount: String,
        intermediateAccountPubKey: String
    ) {
        self.link = link
        self.formatedAmount = formatedAmount
        self.intermediateAccountPubKey = intermediateAccountPubKey
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
            let tokenName = formatedAmount.split(separator: " ").last,
            let tokenValue = formatedAmount.split(separator: " ").first,
            let tokenValue = Double(tokenValue)
        else { return }
        
        analyticsManager.log(event: .sendCreatingLinkEndScreenOpen(
            tokenName: String(tokenName),
            tokenValue: tokenValue,
            pubkey: intermediateAccountPubKey
        ))
    }
    
    func logShareLink() {
        analyticsManager.log(event: .sendClickShareLink)
    }
    
    func logCopyLink() {
        analyticsManager.log(event: .sendClickCopyLink)
    }
}
