//
//  CryptoView.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
//

import KeyAppUI
import SwiftUI
import Combine

/// View of `Crypto` scene
struct CryptoView: View {
    
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoViewModel
    
    private let actionsPanelViewModel: CryptoActionsPanelViewModel
    private let accountsViewModel: CryptoAccountsViewModel
    
    // MARK: - Initializer
    
    init(
        viewModel: CryptoViewModel,
        actionsPanelViewModel: CryptoActionsPanelViewModel,
        accountsViewModel: CryptoAccountsViewModel
    ) {
        self.viewModel = viewModel
        self.actionsPanelViewModel = actionsPanelViewModel
        self.accountsViewModel = accountsViewModel
    }
    
    // MARK: - View content

    private var actionsPanelView: CryptoActionsPanelView {
        CryptoActionsPanelView(viewModel: actionsPanelViewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .pending:
                Text("Pending")
            case .empty:
                Text("Empty")
            case .accounts:
                navigation {
                    CryptoAccountsView(
                        viewModel: accountsViewModel,
                        actionsPanelView: actionsPanelView
                    )
                }
            }
        }
        .onAppear {
            viewModel.viewAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.viewAppeared()
        }
    }
    
    func navigation<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationView {
            ZStack {
                Color(Asset.Colors.smoke.color)
                    .edgesIgnoringSafeArea(.all)
                content()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Button(
                                action: {
                                    viewModel.copyToClipboard()
                                },
                                label: {
                                    ZStack {
                                        Color(Asset.Colors.snow.color)
                                            .cornerRadius(80)
                                        HStack(spacing: 5) {
                                            Image(uiImage: .walletNavigation)
                                            Text(viewModel.address)
                                                .fontWeight(.semibold)
                                                .apply(style: .text3)
                                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                    }
                                }
                            )
                        }
                    }
            }
        }
        .onAppear {
            viewModel.updateAddressIfNeeded()
        }
    }
}

#warning("What is analyticId for this screen?")
