import SolanaSwift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var logOutPresented = false
    @State private var debugPresented = false

    var body: some View {
        sections
            .onAppear {
                viewModel.updateNameIfNeeded()
            }
    }

    private var sections: some View {
        List {
            Group {
                profileSection
                securitySection
                appearanceSection
                communitySection
                appVersionSection
//                #if !RELEASE
                debugSection
//                #endif
            }
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        }
        .listStyle(.insetGrouped)
    }

    private var profileSection: some View {
        Section(header: headerText(L10n.profile)) {
            if viewModel.isNameEnabled {
                Button(
                    action: { viewModel.showView(.username) },
                    label: {
                        cellView(image: .profileIcon, title: L10n.username) {
                            HStack(spacing: 14) {
                                Text(viewModel.name)
                                    .foregroundColor(Color(.mountain))
                                    .font(uiFont: .font(of: .label1))
                                Image(.cellArrow)
                                    .foregroundColor(Color(.mountain))
                            }
                        }
                    }
                )
            }
            Button(
                action: {
                    viewModel.sendSignOutAnalytics()
                    logOutPresented.toggle()
                },
                label: {
                    HStack(spacing: 8) {
                        Spacer()
                        Text(L10n.logOut)
                            .font(uiFont: .font(of: .text2, weight: .semibold))
                        Image(.settingsSignOut)
                        Spacer()
                    }
                    .foregroundColor(Color(.rose))
                }
            )
            .alert(isPresented: $logOutPresented) {
                Alert(
                    title: Text(L10n.doYouWantToLogOut),
                    message: Text(L10n.youWillNeedYourSocialAccountOrPhoneNumberToLogIn),
                    primaryButton: .destructive(Text(L10n.logOut)) {
                        viewModel.signOut()
                    },
                    secondaryButton: .cancel(Text(L10n.stay))
                )
            }
        }
    }

    private var securitySection: some View {
        Section(header: headerText(L10n.security)) {
            Button(
                action: { viewModel.showView(.recoveryKit) },
                label: {
                    SettingsRowView(title: L10n.securityAndPrivacy, withArrow: true) {
                        Image(.recoveryKit)
                            .overlay(
                                AlertIndicatorView(fillColor: Color(.rose))
                                    .opacity(viewModel.deviceShareMigrationAlert ? 1 : 0)
                                    .offset(x: 2.5, y: -2.5),
                                alignment: .topTrailing
                            )
                    }
                }
            )
            Button(
                action: { viewModel.showView(.yourPin) },
                label: { cellView(image: .pinIcon, title: L10n.yourPIN) }
            )
            if viewModel.biometryIsAvailable, viewModel.biometryType != .none {
                cellView(
                    image: viewModel.biometryType == .face ? .faceIdIcon : .touchIdIcon,
                    title: viewModel.biometryType == .face ? L10n.faceID : L10n.touchID
                ) {
                    Toggle("", isOn: $viewModel.biometryIsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(.night)))
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
                    .toggleStyle(SwitchToggleStyle(tint: Color(.night)))
                    .labelsHidden()
            }
        }
    }

    private var communitySection: some View {
        Section(header: headerText("community")) {
            Button(
                action: {
                    viewModel.openTwitter()
                },
                label: { cellView(image: .twitter, title: L10n.followUsOnTwitter, withArrow: false) }
            )

            Button(
                action: {
                    viewModel.openDiscord()
                },
                label: { cellView(image: .discord, title: L10n.joinOurDiscord, withArrow: false) }
            )
        }
    }

    private var appVersionSection: some View {
        Section {
            cellView(image: .settingsAppVersion, title: L10n.appVersion) {
                Text(viewModel.appInfo)
                    .foregroundColor(Color(.mountain))
                    .font(uiFont: .font(of: .label1))
            }
        }
    }

//    #if !RELEASE
    private var debugSection: some View {
        Section {
            Button(
                action: { debugPresented.toggle() },
                label: { cellView(image: nil, title: "Debug Menu") }
            )
        }
        .sheet(isPresented: $debugPresented) {
            DebugMenuView(viewModel: .init())
        }
    }

//    #endif

    private func cellView<Content: View>(image: ImageResource?, title: String,
                                         rightContent: () -> Content) -> some View
    {
        HStack(spacing: 8) {
            cellView(image: image, title: title, withArrow: false)
            Spacer()
            rightContent()
        }
    }

    private func cellView(image: ImageResource?, title: String, withArrow: Bool = true) -> some View {
        HStack(spacing: 12) {
            if let image {
                Image(image)
                    .frame(width: 24, height: 24)
            }
            Text(title)
                .foregroundColor(Color(.night))
                .font(uiFont: .font(of: .text2))
                .lineLimit(1)
            if withArrow {
                Spacer()
                Image(.cellArrow)
                    .foregroundColor(Color(.mountain))
            }
        }
    }

    private func headerText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(Color(.mountain))
            .font(uiFont: .font(of: .text4))
    }
}
