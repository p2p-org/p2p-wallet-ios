//
//  RecipientSearchView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.2022.
//

import KeyAppUI
import SwiftUI

struct RecipientSearchField: View {
    @Binding var text: String
    @Binding var isLoading: Bool
    @Binding var isFirstResponder: Bool

    let past: () -> Void
    let scan: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack {
                FocusedTextField(text: $text, isFirstResponder: $isFirstResponder) { textField in
                    textField.placeholder = L10n.usernameOrAddress
                    textField.autocapitalizationType = .none
                }
                    .frame(height: 24)
                    .padding(.vertical, 12)

                if isLoading {
                    Spinner()
                        .frame(width: 12, height: 12)
                } else if text.isEmpty {
                    Button { past() }
                    label: {
                            Image(uiImage: Asset.Icons.past.image)
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                } else {
                    Button { text = "" }
                    label: {
                            Image(uiImage: .crossIcon)
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                }
            }
            .padding(.horizontal, 18)
            .background(
                Color(Asset.Colors.rain.color)
                    .cornerRadius(radius: 12, corners: .allCorners)
            )

            Button { scan() } label: {
                Image(uiImage: Asset.Icons.qr.image)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }
    }
}

private struct RecipientTextField: UIViewRepresentable {
    @Binding private var isFirstResponder: Bool
    @Binding private var text: String

    init(text: Binding<String>, isFirstResponder: Binding<Bool>) {
        _text = text
        _isFirstResponder = isFirstResponder
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.textViewDidChange),
            for: .editingChanged
        )
        return view
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.isFirstResponder, !isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        } else if !uiView.isFirstResponder, isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }

        @objc func textViewDidChange(_ textField: UITextField) {
            text.wrappedValue = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_: UITextField) {
            isFirstResponder.wrappedValue = true
        }

        func textFieldDidEndEditing(_: UITextField) {
            isFirstResponder.wrappedValue = false
        }
    }
}

struct RecipientSearchField_Previews: PreviewProvider {
    static var previews: some View {
        RecipientSearchField(
            text: .constant("Hello"),
            isLoading: .constant(false),
            isFirstResponder: .constant(false)
        ) {} scan: {}
    }
}
