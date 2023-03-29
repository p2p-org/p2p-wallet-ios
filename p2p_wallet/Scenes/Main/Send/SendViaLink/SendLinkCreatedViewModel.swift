//
//  SendLinkCreatedViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 27.03.2023.
//

import Foundation
import Resolver
import Combine

final class SendLinkCreatedViewModel {
    
    // Dependencies
    @Injected private var notificationService: NotificationService
    
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
        let pasteboard = UIPasteboard.general
        pasteboard.string = link
        notificationService.showInAppNotification(.done(L10n.yourOneTimeLinkIsCopied))
    }
    
    func closeClicked() {
        closeSubject.send()
    }
    
    func shareClicked() {
        shareSubject.send()
    }
}
