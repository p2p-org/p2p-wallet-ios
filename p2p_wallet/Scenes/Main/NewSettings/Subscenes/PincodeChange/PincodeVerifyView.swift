//
//  PincodeEnterView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.09.2022.
//

import Combine
import KeyAppUI
import Resolver
import SwiftUI

struct PincodeVerifyView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @Injected private var pincodeStorage: PincodeStorageType
    var onSuccess: (() -> Void)?
    var forgetPinCode: (() -> Void)?
    private let helpSubject = PassthroughSubject<Void, Never>()
    var help: AnyPublisher<Void, Never> { helpSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack {
            // Header
            VStack {
                Image(uiImage: .changePincode)
                    .resizable()
                    .frame(
                        minWidth: 85,
                        maxWidth: 160,
                        minHeight: 64,
                        maxHeight: 120
                    )
                    .aspectRatio(CGSize(width: 160, height: 120), contentMode: .fit)

                Text(L10n.yourCurrentPINCode)
                    .apply(style: .title2)
                    .padding(.top, 24)
            }
            .padding(.top, 24)

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
            )
            .frame(minHeight: 332)
            .padding(.top, 36)
            .layoutPriority(-1)

            // Forgot your  PIN
            Button {
                forgetPinCode?()
            }
            label: {
                Text(L10n.iForgotPIN)
                    .apply(style: .text1)
                    .foregroundColor(Color(Asset.Colors.sky.color))
                    .padding(.top, 24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    helpSubject.send()
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
        .previewDevice("iPhone 12 Pro Max")
        NavigationView {
            PincodeVerifyView()
                .navigationTitle(Text("Change PIN"))
                .navigationBarTitleDisplayMode(.inline)
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
    }
}
