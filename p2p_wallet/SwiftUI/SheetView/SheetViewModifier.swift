//
//  SheetViewModifier.swift
//  p2p_wallet
//
//  Created by Ivan on 01.10.2022.
//

import Foundation
import SwiftUI

struct SheetViewModifier: ViewModifier {
    @ObservedObject private var manager = SheetManager.shared
    let headerState: CustomSheetView.HeaderState

    func body(content: Content) -> some View {
        content
//            .overlay {
//                if manager.action == .present {
//                    CustomSheetView(headerState: headerState) {
//                        withAnimation(.spring()) {
//                            manager.dismiss()
//                        }
//                    }
//                }
//            }
    }
}
