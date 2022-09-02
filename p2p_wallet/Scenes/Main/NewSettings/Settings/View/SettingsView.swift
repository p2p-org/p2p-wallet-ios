//
//  SettingsView.swift
//  p2p_wallet
//
//  Created by Ivan on 30.08.2022.
//

import KeyAppUI
import SolanaSwift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var logOutPresented = false
    @State private var debugPresented = false

    var body: some View {
        NavigationView {
            sections
                .navigationTitle(L10n.settings)
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.updateNameIfNeeded()
        }
    }

    private var sections: some View {
        List {
            profileSection
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            securitySection
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            appearanceSection
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            if Environment.current != .release {
                debugSection
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
            appVersionSection
        }
        .listStyle(.insetGrouped)
    }

    private var profileSection: some View {
        Section(header: headerText(L10n.profile)) {
            Button(
                action: { viewModel.showView(.username) },
                label: {
                    cellView(image: .profileIcon, title: L10n.username) {
                        HStack(spacing: 14) {
                            Text(viewModel.name)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(uiFont: .font(of: .label1))
                            Image(uiImage: .cellArrow)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                        }
                    }
                }
            )
            Button(
                action: {
                    viewModel.sendSignOutAnalytics()
                    logOutPresented.toggle()
                },
                label: {
                    HStack(spacing: 8) {
                        Spacer()
                        Text(L10n.signOut)
                            .font(uiFont: .font(of: .text2, weight: .semibold))
                        Image(uiImage: .settingsSignOut)
                        Spacer()
                    }
                    .foregroundColor(Color(Asset.Colors.rose.color))
                }
            )
                .alert(isPresented: $logOutPresented) {
                    Alert(
                        title: Text(L10n.areYouSureYouWantToSignOut),
                        message: Text(L10n.withoutTheBackupYouMayNeverBeAbleToAccessThisAccount),
                        primaryButton: .destructive(Text(L10n.signOut)) {
                            viewModel.signOut()
                        },
                        secondaryButton: .cancel(Text(L10n.stay))
                    )
                }
        }
    }

    private var securitySection: some View {
        Section(header: headerText(L10n.security)) {
            // TODO: - Disabled before onboarding finish
//            Button(
//                action: { viewModel.showView(.recoveryKit) },
//                label: { cellView(image: .recoveryKit, title: L10n.recoveryKit) }
//            )
            Button(
                action: { viewModel.showView(.yourPin) },
                label: { cellView(image: .pinIcon, title: L10n.yourPIN) }
            )
            Button(
                action: { viewModel.showView(.network) },
                label: { cellView(image: .networkIcon, title: L10n.network) }
            )
            if viewModel.biometryIsAvailable, viewModel.biometryType != .none {
                cellView(
                    image: viewModel.biometryType == .face ? .faceIdIcon : .touchIdIcon,
                    title: viewModel.biometryType == .face ? L10n.faceID : L10n.touchID
                ) {
                    Toggle("", isOn: $viewModel.biometryIsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(Asset.Colors.night.color)))
                        .labelsHidden()
                }
                .alert(isPresented: $viewModel.errorAlertPresented) {
                    Alert(
                        title: Text(L10n.error.uppercaseFirst),
                        message: Text(viewModel.error?.readableDescription ?? "")
                    )
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section(header: headerText(L10n.appearance)) {
            cellView(image: .hideZeroBalance, title: L10n.hideZeroBalances) {
                Toggle("", isOn: $viewModel.zeroBalancesIsHidden)
                    .toggleStyle(SwitchToggleStyle(tint: Color(Asset.Colors.night.color)))
                    .labelsHidden()
            }
        }
    }

    private var debugSection: some View {
        Section(header: headerText("Debug")) {
            Button(
                action: { debugPresented.toggle() },
                label: { cellView(image: UIImage(), title: "Debug Menu") }
            )
        }
        .sheet(isPresented: $debugPresented) {
            DebugMenuView(viewModel: .init())
        }
    }

    private var appVersionSection: some View {
        Section(header: headerText(viewModel.appInfo)) {}
    }

    private func cellView<Content: View>(image: UIImage, title: String, rightContent: () -> Content) -> some View {
        HStack(spacing: 8) {
            cellView(image: image, title: title, withArrow: false)
            Spacer()
            rightContent()
        }
    }

    private func cellView(image: UIImage, title: String, withArrow: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2))
                .lineLimit(1)
            if withArrow {
                Spacer()
                Image(uiImage: .cellArrow)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }

    private func headerText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .font(uiFont: .font(of: .text4))
    }
}
