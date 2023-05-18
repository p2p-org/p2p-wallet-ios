//
//  SearchBar.swift
//  p2p_wallet
//
//  Created by Ivan on 14.04.2023.
//

import SwiftUI
import KeyAppUI

struct SearchBar: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(._767680))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if isSearching {
                            Button(
                                action: {
                                    text = ""
                                },
                                label: {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            )
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    isSearching = true
                }
            if isSearching {
                Button(
                    action: {
                        isSearching = false
                        UIApplication.shared.endEditing()
                        text = ""
                    },
                    label: {
                        Text(L10n.cancel)
                    }
                )
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
