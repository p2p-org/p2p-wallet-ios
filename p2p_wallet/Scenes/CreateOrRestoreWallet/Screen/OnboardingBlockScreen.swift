// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppUI
import SwiftUI

struct OnboardingBlockScreen: View {
    @State var loading: Bool = false

    let contentTitle: String
    @State var untilTimestamp: Date = .init()
    @State var formattedCountDown: String = "00:00"

    let onHome: () async throws -> Void
    let onCompletion: (() async throws -> Void)?
    let onTermAndCondition: () -> Void

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: .init(
                    image: .coins,
                    title: contentTitle,
                    subtitle: L10n.YouDidnTUseAnyOf5Codes.forYourSafetyWeFreezedAccountForMin(formattedCountDown)
                )
            )
                .onAppear { formatCountdown() }
                .onReceive(timer) { _ in
                    if Date() > untilTimestamp {
                        timer.upstream.connect().cancel()

                        Task {
                            guard loading == false else { return }
                            loading = true
                            defer { loading = false }
                            do { try await onCompletion?() }
                        }
                    }
                    formatCountdown()
                }
                .padding(.bottom, 48)
                .padding(.horizontal, 20)

            BottomActionContainer {
                VStack {
                    TextButtonView(title: L10n.startingScreen, style: .outlineWhite, size: .large) {
                        Task {
                            guard loading == false else { return }
                            loading = true
                            defer { loading = false }
                            do { try await onHome() }
                        }
                    }
                    .frame(height: TextButton.Size.large.height)

                    OnboardingTermAndConditionButton(onPressed: onTermAndCondition)
                        .padding(.top, 24)
                }
            }
        }.onboardingScreen()
    }

    private let formatter: DateComponentsFormatter = {
        var formatter = DateComponentsFormatter()
        // formatter.zeroFormattingBehavior = .pad
        // formatter.allowedUnits = [.minute, .second]
        return formatter
    }()

    private func formatCountdown() {
        let interval: TimeInterval = untilTimestamp.timeIntervalSinceReferenceDate - Date()
            .timeIntervalSinceReferenceDate

        // guard interval > 0 else {
        //     formattedCountDown = "00:00"
        //     return
        // }

        formattedCountDown = formatter.string(from: interval)!
        print(formattedCountDown)
    }
}
