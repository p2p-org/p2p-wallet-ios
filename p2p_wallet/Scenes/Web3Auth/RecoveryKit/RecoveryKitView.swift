// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppKitCore
import KeyAppUI
import Onboarding
import Resolver
import SwiftUI

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
                    Text(L10n.securityAndPrivacy)
                        .fontWeight(.bold)
                        .apply(style: .title2)
                    Text(viewModel.model != nil ?
                        // Web3Auth user
                        L10n.toAccessYourAccountFromAnotherDeviceYouNeedToUseAny2FactorsFromTheListBelow :
                        // Seedphrase user
                        L10n.SeedPhraseIsTheOnlyWayToAccessYourFundsOnAnotherDevice
                        .keyAppDoesnTHaveAccessToThisInformation)
                        .apply(style: .text2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(Color(Asset.Colors.lime.color))
                .cornerRadius(28)
                .padding(.top, safeAreaInsets.top + 50)

                // TKey info
                if let metadata = viewModel.model {
                    VStack(alignment: .leading) {
                        Text(L10n.multiFactorAuthentication.uppercased())
                            .apply(style: .caps)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .padding(.leading, 16)

                        VStack(spacing: 0) {
                            RecoveryKitRowView(
                                icon: .deviceIcon,
                                title: L10n.device,
                                subtitle: Device.getDeviceNameFromIdentifier(metadata.deviceName),

                                alert: metadata.isAnotherDevice,
                                titleAction: "Manage",
                                action: metadata.isAnotherDevice ? { viewModel.openDevices() } : nil
                            )
                            RecoveryKitRowView(
                                icon: .callIcon,
                                title: L10n.phone,
                                subtitle: metadata.phoneNumber
                            )
                            RecoveryKitRowView(
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

                        Text(L10n
                            .KeyAppRespectsYourPrivacyItCanTAccessYourFundsOrPersonalDetails
                            .yourInformationStaysSecurelyStoredOnYourDeviceAndInTheBlockchain)
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
                        RecoveryKitRowView(
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
        .onAppear {
            viewModel.onAppear()
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
                ethPublic: "1234",
                deviceName: "iPhone 11",
                email: "abc@gmail.com",
                authProvider: "google",
                phoneNumber: "+79183331231"
            )
        )

        let service = WalletMetadataServiceImpl(
            currentUserWallet: MockCurrentUserWallet.random(),
            errorObserver: MockErroObserver(),
            localMetadataProvider: provider,
            remoteMetadataProvider: [provider]
        )

        Task { await service.synchronize() }

        return NavigationView {
            RecoveryKitView(
                viewModel: .init(walletMetadataService: service)
            )
        }
    }
}
