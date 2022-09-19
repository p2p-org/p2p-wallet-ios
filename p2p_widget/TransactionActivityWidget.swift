//
//  TransactionActivityWidget.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.09.2022.
//

import SwiftUI
import WidgetKit

@main
struct TransactionActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TransactionActivityAttributes.self) { context in
            Text(context.attributes.transactionDescription)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    
                    VStack {
                        Text(context.attributes.transactionDescription )
                            .lineLimit(1)
                            .font(.caption)
                        Text(context.state.status)
                            .lineLimit(1)
                            .font(.caption)
                    }
                        
                        
                    
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                                    Label {
                                        Text(timerInterval: context.state.deliveryTimer, countsDown: true)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 50)
                                            .monospacedDigit()
                                    } icon: {
                                        Image(systemName: "timer")
                                            .foregroundColor(.indigo)
                                    }
                                    .font(.title2)
                                }
            } compactLeading: {
                Label {
                    Text("💸")
                } icon: {
                    Image(systemName: "bagarrow.right.arrow.left.circle.fill")
                        .foregroundColor(.indigo)
                }
            } compactTrailing: {
                Text(timerInterval: context.state.deliveryTimer, countsDown: true)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 40)
                                    .font(.caption2)
            } minimal: {
                
                                }
               // This is used when there are multiple activities
//                    Image(systemName: "timer")
            }
        }
    }

