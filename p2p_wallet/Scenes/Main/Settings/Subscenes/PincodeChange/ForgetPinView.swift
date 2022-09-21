// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Resolver
import SwiftUI

struct ForgetPinView: View {
    @State var isLoading: Bool = false
    @Injected var userWalletManager: UserWalletManager
    private let text: String

    var close: (() -> Void)?
    var onLogout: (() -> Void)?

    init(text: String = L10n.ifYouForgetYourPINYouCanLogOutAndCreateANewOneWhenYouLogInAgain) {
        self.text = text
    }

    var body: some View {
        VStack {
            // Indicator
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.vertical, 6)

            // Header

            HStack {
                SwiftUI.EmptyView()
                    .frame(width: 24)
                Spacer()
                Text(L10n.forgetYouPIN)
                    .fontWeight(.semibold)
                    .apply(style: .title3)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                Spacer()
                closeButton
                    .offset(x: 0, y: -6)
            }.padding(.horizontal, 16)

            // Divider
            Divider()

            // Body
            Text(text)
                .apply(style: .text1)
                .padding(.horizontal, 40)
                .padding(.vertical, 24)

            // Logout button
            TextButtonView(title: L10n.logout, style: .second, size: .large, isLoading: isLoading) {
                if let onLogout = onLogout {
                    onLogout()
                } else {
                    guard isLoading == false else { return }
                    Task {
                        isLoading = true
                        defer { isLoading = false }
                        do { try await userWalletManager.remove() }
                    }
                }
            }
            .frame(height: TextButton.Size.large.height)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(.white))
        .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
    }

    var closeButton: some View {
        Button {
            close?()
        }
        label: {
            ZStack {
                Circle()
                    .fill(Color(Asset.Colors.rain.color))
                Image(uiImage: Asset.MaterialIcon.close.image)
                    .resizable()
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .frame(width: 16, height: 16)
            }.frame(width: 24, height: 24)
        }
    }
}

extension ForgetPinView {
    var viewHeight: CGFloat {
        max(20, UIApplication.shared.kWindow?.safeAreaInsets.bottom ?? 0) + 300
    }
}

struct ForgetPinView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color(.gray)
            ForgetPinView()
        }
    }
}
