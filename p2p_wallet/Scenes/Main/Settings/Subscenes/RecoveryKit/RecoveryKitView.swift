// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Onboarding
import SwiftUI
import Resolver

struct RecoveryKitView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @ObservedObject var viewModel: RecoveryKitViewModel
    @ObservedObject var walletSettings: WalletSettings = Resolver.resolve()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card
                VStack(spacing: 8) {
                    Image(uiImage: .lockOutline)
                        .padding(.top, 4)
                    Text(L10n.yourRecoveryKit)
                        .fontWeight(.bold)
                        .apply(style: .title2)
                    Text(L10n.IfYouSwitchDevicesYouCanEasilyRestoreYourWallet.noPrivateKeysNeeded)
                        .apply(style: .text2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(Color(Asset.Colors.lime.color))
                .cornerRadius(28)
                // .overlay(
                //    helpButton,
                //    alignment: .topTrailing
                // )
                .padding(.top, safeAreaInsets.top + 50)

                // TKey info
                if let metadata = viewModel.walletMetadata {
                    VStack(alignment: .leading) {
                        Text(L10n.multiFactorAuthentication)
                            .apply(style: .caps)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .padding(.leading, 16)

                        VStack(spacing: 0) {
                            RecoveryKitRow(
                                icon: .deviceIcon,
                                title: L10n.device,
                                subtitle: Device.getDeviceNameFromIdentifier(metadata.deviceName)
                            )
                            RecoveryKitRow(
                                icon: .callIcon,
                                title: L10n.phone,
                                subtitle: metadata.phoneNumber
                            )
                            RecoveryKitRow(
                                icon: authProviderIcon(provider: metadata.authProvider) ?? .appleIcon,
                                title: authProviderName(provider: metadata.authProvider),
                                subtitle: metadata.email
                            )
                        }
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .background(Color(Asset.Colors.snow.color))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                        )

                        Text(L10n.YourPrivateKeyIsSplitIntoMultipleFactors
                            .AtLeastYouShouldHaveThreeFactorsButYouCanCreateMore
                            .toLogInToDifferentDevicesYouNeedAtLeastTwoFactors)
                            .apply(style: .label1)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .padding(.leading, 16)
                    }.frame(maxWidth: .infinity)
                }

                // Seed phrase button
                RecoveryKitCell(
                    icon: .keyIcon,
                    title: L10n.seedPhrase
                ) {
                    viewModel.openSeedPhrase()
                }
                
                if walletSettings.deleteWeb3AuthRequest == nil {
                    RecoveryKitCell(
                        icon: .alertIcon,
                        title: L10n.deleteMyAccount
                    ) {
                        viewModel.deleteAccount()
                    }
                } else {
                    Button {
                        viewModel.deleteAccount()
                    } label: {
                        RecoveryKitRow(
                            icon: .alertIcon,
                            title: L10n.deleteMyAccount,
                            subtitle: L10n.pending.uppercaseFirst + "..."
                        )
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .background(Color(Asset.Colors.snow.color))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                        )
                    }
                }
                
            }.padding(.horizontal, 16)
        }
        .background(Color(Asset.Colors.cloud.color))
        .edgesIgnoringSafeArea(.top)
    }

    var helpButton: some View {
        Button {
            viewModel.openHelp()
        } label: {
            Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                .frame(width: 30, height: 30)
                .padding(.top, 20)
                .padding(.trailing, 20)
        }
    }

    func authProviderName(provider: String) -> String {
        switch provider {
        case "apple": return "AppleID"
        case "google": return "Google"
        default: return "Google"
        }
    }

    func authProviderIcon(provider: String) -> UIImage? {
        switch provider {
        case "apple": return .appleIcon
        case "google": return .google
        default: return .google
        }
    }
}

struct RecoveryKitView_Previews: PreviewProvider {
    static var previews: some View {
        
        let provider = MockedWalletMeradataProvider(
            .init(
                deviceName: "iPhone 11",
                email: "abc@gmail.com",
                authProvider: "google",
                phoneNumber: "+79183331231"
            )
        )
        
        let service = WalletMetadataService(
            localProvider: provider,
            remoteProvider: provider
        )
        
        Task { try await service.update() }
        
        return NavigationView {
            RecoveryKitView(
                viewModel: .init(walletMetadataService: service)
            )
        }
    }
}
