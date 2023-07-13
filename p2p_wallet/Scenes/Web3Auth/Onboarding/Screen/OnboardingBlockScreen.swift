// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import KeyAppUI
import SwiftUI

struct OnboardingBlockScreen: View {
    @State var loading: Bool = false

    let primaryButtonAction: String
    let contentTitle: String
    let contentSubtitle: (_ p1: Any) -> String

    @State var untilTimestamp: Date = .init()
    @State var formattedCountDown: String = "00:00"

    let onHome: () async throws -> Void
    let onCompletion: (() async throws -> Void)?
    let onTermsOfService: () -> Void
    let onPrivacyPolicy: () -> Void
    let onInfo: (() -> Void)?

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: .init(
                    image: .womanHardError,
                    title: contentTitle,
                    subtitle: contentSubtitle(formattedCountDown)
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

            BottomActionContainer {
                VStack {
                    TextButtonView(title: primaryButtonAction, style: .outlineWhite, size: .large) {
                        Task {
                            guard loading == false else { return }
                            loading = true
                            defer { loading = false }
                            do { try await onHome() }
                        }
                    }
                    .frame(height: TextButton.Size.large.height)

                    OnboardingTermsAndPolicyButton(
                        termsPressed: onTermsOfService,
                        privacyPolicyPressed: onPrivacyPolicy
                    )
                    .padding(.top, 24)
                }
            }
        }
        .background(Color(.lime))
        .ignoresSafeArea()
        .onboardingNavigationBar(title: "", onInfo: onInfo)
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

        guard interval > 0 else {
            formattedCountDown = "0 sec"
            return
        }

        formattedCountDown = "\(formatter.string(from: interval)!) \(interval > 60 ? "min" : "sec")"
    }
}

struct OnboardingBlockScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingBlockScreen(
            primaryButtonAction: "Recovery Kit",
            contentTitle: L10n.soLetSBreathe,
            contentSubtitle: { (_: Any) in L10n.YouVeUsedAll5Codes.TryAgainLater.forHelpContactSupport }
        ) {} onCompletion: {} onTermsOfService: {} onPrivacyPolicy: {} onInfo: {}
    }
}
