//
//  PincodeEnterView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.09.2022.
//

import KeyAppUI
import Resolver
import SwiftUI

struct PincodeVerifyView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @Injected private var pincodeStorage: PincodeStorageType
    var onSuccess: (() -> Void)?
    var forgetPinCode: (() -> Void)?

    var body: some View {
        VStack {
            // Header
            VStack {
                Image(uiImage: .lockMagic)
                    .resizable()
                    .frame(width: 160, height: 120)

                Text(L10n.yourCurrentPIN)
                    .apply(style: .title2)
                    .padding(.top, 24)
            }.padding(.top, 24)

            Spacer()

            // Pincode
            SwiftPinCodeView(
                pinCode: pincodeStorage.pinCode,
                maxAttemptsCount: nil,
                stackViewSpacing: 24,
                onSuccess: { _ in onSuccess?() },
                onFailed: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            ).padding(.top, 40)

            // Forgot your  PIN
            Button {
                forgetPinCode?()
            }
            label: {
                Text(L10n.forgotYourPIN)
                    .apply(style: .text1)
                    .foregroundColor(Color(Asset.Colors.sky.color))
                    .padding(.top, 24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Pressed")
                } label: {
                    Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                }
            }
        }
        .padding(.top, safeAreaInsets.top + 50)
        .padding(.bottom, 54)
        .background(Color(Asset.Colors.rain.color))
        .edgesIgnoringSafeArea(.all)
    }
}

private struct SwiftPinCodeView: UIViewRepresentable {
    let pinCode: String?
    let maxAttemptsCount: Int?
    let stackViewSpacing: CGFloat?
    let onSuccess: ((String?) -> Void)?
    let onFailed: (() -> Void)?

    func makeUIView(context _: Context) -> PinCode {
        let pinCode = PinCode(
            correctPincode: pinCode,
            maxAttemptsCount: maxAttemptsCount,
            bottomLeftButton: nil
        )

        pinCode.stackViewSpacing = stackViewSpacing ?? 24
        pinCode.resetingDelayInSeconds = 2
        pinCode.onSuccess = onSuccess
        pinCode.onFailed = onFailed

        return pinCode
    }

    func updateUIView(_ view: PinCode, context _: Context) {
        view.onSuccess = onSuccess
        view.onFailed = onFailed
    }
}

struct PincodeVerifyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PincodeVerifyView()
                .navigationTitle(Text("Change PIN"))
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
