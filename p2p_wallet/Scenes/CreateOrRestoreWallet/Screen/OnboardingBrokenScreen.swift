// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import KeyAppUI
import SwiftUI

struct OnboardingBrokenScreen<CustomActions: View>: View {
    let title: String
    let contentData: OnboardingContentData

    let back: (() async throws -> Void)?
    let info: (() -> Void)?
    let help: (() -> Void)?

    @ViewBuilder var customActions: CustomActions

    @State var loading: Bool = false

    init(
        title: String,
        contentData: OnboardingContentData,
        back: (() async throws -> Void)? = nil,
        info: (() -> Void)? = nil,
        help: (() -> Void)? = nil,
        @ViewBuilder customActions: () -> CustomActions
    ) {
        self.title = title
        self.contentData = contentData
        self.back = back
        self.info = info
        self.help = help
        self.customActions = customActions()
    }

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: contentData
            )
                .padding(.horizontal, 40)
                .padding(.top, 60)
                .padding(.bottom, 48)
            BottomActionContainer {
                VStack {
                    customActions

                    if let help = help {
                        TextButtonView(
                            title: L10n.support,
                            style: .inverted,
                            size: .large,
                            leading: Asset.MaterialIcon.newReleasesOutlined.image,
                            onPressed: { help() }
                        )
                            .frame(height: TextButton.Size.large.height)
                    }

                    if let back = back {
                        TextButtonView(
                            title: L10n.startingScreen,
                            style: .ghostLime,
                            size: .large,
                            onPressed: {
                                Task {
                                    guard loading == false else { return }
                                    loading = true
                                    defer { loading = false }

                                    try await back()
                                }
                            }
                        )
                            .frame(height: TextButton.Size.large.height)
                    }
                }
            }
        }
        .onboardingNavigationBar(
            title: title,
            onBack: nil,
            onInfo: info != nil ? { info!() } : nil
        )
        .onboardingScreen()
    }
}

extension OnboardingBrokenScreen where CustomActions == SwiftUI.EmptyView {
    init(
        title: String,
        contentData: OnboardingContentData,
        back: (() async throws -> Void)? = nil,
        info: (() -> Void)? = nil,
        help: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            contentData: contentData,
            back: back,
            info: info,
            help: help,
            customActions: { SwiftUI.EmptyView() }
        )
    }
}

struct OnboardingBrokenScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingBrokenScreen(
                title: L10n.restore,
                contentData: .init(
                    image: .easyToStart,
                    title: L10n.easyToStart,
                    subtitle: L10n.createYourAccountIn1Minute
                ),
                back: {},
                info: {},
                help: {}
            )
        }
    }
}
