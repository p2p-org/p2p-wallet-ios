//
//  RecoveryKitChangeDeviceShareView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06/06/2023.
//

import KeyAppUI
import SwiftUI

struct RecoveryKitChangeDeviceShareView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.weVeNoticedThatYouReUsingANewDevice)
                        .apply(style: .text3)
                    Text(L10n
                        .forSecurityChangeYourAuthorizationDeviceToRestoreAccessForSecurityChangeYourAuthorizationDeviceToRestoreAccessIfNeeded)
                        .apply(style: .text3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                VStack {
                    VStack(spacing:4) {
                        VStack(alignment: .leading) {
                            Text(L10n.thisDevice)
                                .apply(style: .caps)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .padding(.leading, 16)

                            HStack {
                                Image(uiImage: .deviceIcon)
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 16)
                                Text("iPhone 13")
                                    .fontWeight(.semibold)
                                    .apply(style: .text3)
                                Spacer()
                                Button {} label: {
                                    Text(L10n.setUp)
                                        .fontWeight(.semibold)
                                        .apply(style: .text4)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(Asset.Colors.rain.color))
                                .cornerRadius(20)
                            }
                            .padding(.trailing, 16)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .background(Color(Asset.Colors.snow.color))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 40)
                    Spacer()

                    VStack(spacing: 4) {
                        VStack(alignment: .leading) {
                            Text(L10n.thisDevice)
                                .apply(style: .caps)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .padding(.leading, 16)

                            HStack {
                                Image(uiImage: .deviceIcon)
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 16)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("iPhone 8")
                                        .fontWeight(.semibold)
                                        .apply(style: .text3)
                                        .padding(.top, 16)
                                    HStack(spacing: 4) {
                                        Image(uiImage: .warningIcon)
                                            .foregroundColor(Color(Asset.Colors.rose.color))
                                        Text(L10n.makeSureThisIsStillYourDevice)
                                            .fontWeight(.regular)
                                            .apply(style: .label1)
                                            .foregroundColor(Color(Asset.Colors.rose.color))
                                    }
                                    .padding(.bottom, 12)
                                }
                                Spacer()
                            }
                            .padding(.trailing, 16)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .background(Color(Asset.Colors.snow.color))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
                            )
                            Text(L10n.attentionIfYouUpdateYourCurrentDeviceYouWillNotBeAbleToUseTheOldDeviceForRecovery)
                                .apply(style: .label1)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 28)
                }
            }
        }
        .background(
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()
        )
    }
}

struct RecoveryKitChangeDeviceShareView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryKitChangeDeviceShareView()
    }
}
