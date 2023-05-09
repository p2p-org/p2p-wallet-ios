//
//  WrapperForSearchingView.swift
//  p2p_wallet
//
//  Created by Ivan on 19.04.2023.
//

import SwiftUI

@available(iOS 15.0, *)
struct WrapperForSearchingView<Content: View>: View {
    
    @SwiftUI.Environment(\.isSearching) private var isSearching
    
    @Binding var searching: Bool
    @ViewBuilder var content: Content
    
    var body: some View {
        content
            .onChange(of: isSearching) { value in
                searching = value
            }
    }
}
