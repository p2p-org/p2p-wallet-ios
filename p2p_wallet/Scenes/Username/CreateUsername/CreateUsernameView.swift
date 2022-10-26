import KeyAppUI
// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import SwiftUI

struct CreateUsernameView: View {
    @ObservedObject var viewModel: CreateUsernameViewModel

    private let mainColor = Color(Asset.Colors.night.color)
    private let errorColor = Color(Asset.Colors.rose.color)

    var body: some View {
        ZStack {
            Color(viewModel.backgroundColor)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
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
            .edgesIgnoringSafeArea(.bottom)
        }
        .onTapGesture {
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

            Text(L10n.receiveAndSendCryptocurrenciesInKeyApp)
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
                title: viewModel.actionText,
                style: .inverted,
                size: .large,
                isLoading: viewModel.isLoading,
                onPressed: {}
            )
                .onTapGesture {
                    viewModel.createUsername.send()
                }
                .frame(height: 56)
                .disabled(viewModel.status != .available)
        }
    }

    var usernameField: some View {
        HStack(spacing: 0) {
            FocusedTextField(
                text: $viewModel.username,
                isFirstResponder: $viewModel.isTextFieldFocused,
                validation: viewModel.usernameValidation,
                configuration: { textField in
                    textField.font = UIFont.font(of: .title3)
                    textField.textColor = Asset.Colors.night.color
                    textField.autocapitalizationType = .none
                    textField.returnKeyType = .done
                }
            )
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 56)
                .padding(.leading, 16)

            Text(viewModel.domain)
                .font(.system(size: UIFont.fontSize(of: .title3)))
                .foregroundColor(mainColor.opacity(0.3))
                .padding(.horizontal, 6)

            Button(action: viewModel.clearUsername.send) {
                Image(uiImage: Asset.MaterialIcon.clear.image)
                    .accentColor(mainColor)
            }
            .frame(width: 16, height: 16)
            .padding(.trailing, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .onTapGesture {
                    viewModel.isTextFieldFocused = true
                }
        )
        .frame(height: 56)
    }

    var skipButton: some View {
        Button(L10n.skip.uppercaseFirst, action: viewModel.skip.send)
            .foregroundColor(mainColor)
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
        CreateUsernameView(
            viewModel: CreateUsernameViewModel(
                parameters: CreateUsernameParameters(
                    backgroundColor: Asset.Colors.rain.color
                )
            )
        )
    }
}
