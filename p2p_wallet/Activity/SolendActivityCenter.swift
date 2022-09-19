//
//  SolendActivityCenter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.09.2022.
//

import Foundation
import Solend
import Resolver
import ActivityKit
import Combine


@available(iOS 16.1, *)
class SolendActivityCenter {
    var subscriptions = Set<AnyCancellable>()
    
    @Injected var actionService: SolendActionService
    
    init() {
        for activity in Activity<TransactionActivityAttributes>.activities {
            Task {
                await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
            }
        }
        
        print("Start activity center")
        actionService.currentAction
            .sink { action in
                guard let action = action else { return }
                
                Task {
                    if let activity = self.look(transactionID: action.transactionID) {
                        await activity.update(using: .init(status: "In process", deliveryTimer: activity.contentState.deliveryTimer))
                    } else {
                        do {
                            print("Create deposit activity")
                            var future = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
                            let date = Date.now...future
                            let attributes = TransactionActivityAttributes(transactionID: action.transactionID, transactionDescription: "💸 Depositing")
                            _ = try Activity<TransactionActivityAttributes>.request(attributes: attributes, contentState: .init(status: "In process", deliveryTimer: date))
                        } catch {
                            print(error)
                        }
                    }
                }
            }.store(in: &subscriptions)
    }
    
    func look(transactionID: String) -> Activity<TransactionActivityAttributes>? {
        for activity in Activity<TransactionActivityAttributes>.activities {
            if activity.attributes.transactionID == transactionID {
                return activity
            }
        }
        return nil
    }
}
