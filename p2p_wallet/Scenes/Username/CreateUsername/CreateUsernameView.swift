import KeyAppUI
// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import SwiftUI

struct CreateUsernameView: View {
    @ObservedObject var viewModel: CreateUsernameViewModel

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                VStack(spacing: .zero) {
                    informativeContent

                    usernameField
                        .padding(.top, 24)

                    statusView
                        .padding(.vertical, 4)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 20)

                Spacer()

                bottomContainer
            }
            .ignoresSafeArea(.keyboard)
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: skipButton)
        .onAppear {
            viewModel.isTextFieldFocused = true
        }
        .onDisappear {
            viewModel.isTextFieldFocused = false
        }
    }
}

// MARK: - Subviews

private extension CreateUsernameView {
    var informativeContent: some View {
        VStack(spacing: 0) {
            Image(uiImage: .nameWallet)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 187.5)

            Text(L10n.pickYourUsername)
                .font(.system(size: UIFont.fontSize(of: .title2), weight: .bold))
                .textStyle()
                .padding(.top, 16)

            Text(L10n.YourUsernameWillBeUsedToSendAndReceiveCryptoWithYourFriendsOnKeyApp
                .theNameCannotBeChanged)
                .font(.system(size: UIFont.fontSize(of: .text3), weight: .regular))
                .textStyle()
                .padding(.top, 12)
        }
    }

    var statusView: some View {
        HStack(spacing: 0) {
            if viewModel.status == .processing {
                CircularProgressIndicatorView(
                    backgroundColor: Asset.Colors.night.color.withAlphaComponent(0.6),
                    foregroundColor: Asset.Colors.night.color
                )
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.status == .processing)
            }

            Text(viewModel.statusText)
                .foregroundColor(viewModel.status == .unavailable ? errorColor : mainColor)
                .font(.system(size: UIFont.fontSize(of: .label1)))
                .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)

            Spacer()
        }
    }

    var bottomContainer: some View {
        BottomActionContainer {
            TextButtonView(
                title: L10n.createName,
                style: .inverted,
                size: .large,
                onPressed: { [weak viewModel] in
                    viewModel?.createUsername.send()
                }
            )
                .frame(height: 56)
        }
    }

    var usernameField: some View {
        FocusedTextField(
            text: $viewModel.username,
            isFirstResponder: $viewModel.isTextFieldFocused,
            configuration: { textField in
                textField.font = UIFont.font(of: .text3)
                textField.textColor = Asset.Colors.night.color
                textField.returnKeyType = .done
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 56))
                textField.leftView = paddingView
                textField.rightView = paddingView
                textField.leftViewMode = .always
                textField.rightViewMode = .always
            }
        )
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .frame(height: 56)
    }

    var skipButton: some View {
        Button(L10n.skip.uppercaseFirst, action: viewModel.requireSkip.send)
            .foregroundColor(mainColor)
    }

    var background: some View {
        Color(Asset.Colors.lime.color)
            .edgesIgnoringSafeArea(.all)
    }

    var mainColor: Color {
        Color(Asset.Colors.night.color)
    }

    var errorColor: Color {
        Color(Asset.Colors.rose.color)
    }
}

private extension Text {
    func textStyle() -> some View {
        foregroundColor(Color(Asset.Colors.night.color))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CreateUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateUsernameView(viewModel: CreateUsernameViewModel())
        }
    }
}
