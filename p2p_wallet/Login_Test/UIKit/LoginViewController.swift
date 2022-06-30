import BEPureLayout
import Combine
import CombineCocoa
import Foundation
import SwiftUI

final class LoginViewController: BaseViewController {
    private let viewModel: LoginViewModel
    private var subscriptions = [AnyCancellable]()

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    override func build() -> UIView {
        BEVStack {
            UILabel(text: "Welcome from UIKit", textSize: 30, weight: .bold, textAlignment: .center)
                .padding(.init(all: 16))
            UITextField(placeholder: "Username", textContentType: .username, horizontalPadding: 16)
                .setup { view in
                    view.textPublisher
                        .map { $0 ?? "" }
                        .sink { [weak self] value in
                            self?.viewModel.username = value
                        }
                        .store(in: &subscriptions)
                }
                .padding(.init(x: 0, y: 16))

            UITextField(
                placeholder: "Password",
                textContentType: .password,
                isSecureTextEntry: true,
                horizontalPadding: 16
            )
                .setup { view in
                    view.textPublisher
                        .map { $0 ?? "" }
                        .sink { [weak self] value in
                            self?.viewModel.password = value
                        }
                        .store(in: &subscriptions)
                }
                .padding(.init(x: 0, y: 16))
            UILabel(text: nil, textColor: .red, numberOfLines: 0)
                .setup { view in
                    viewModel.recommendation
                        .sink { [weak view] recommendation in
                            view?.text = recommendation
                        }
                        .store(in: &subscriptions)
                }
                .padding(.init(all: 16))
            UIButton(label: "Login")
                .setup { button in
                    button.setTitleColor(.blue, for: .normal)
                    button.setTitleColor(.gray, for: .disabled)
                    viewModel.isCredenticalsValid
                        .sink { [weak button] isCredenticalsValid in
                            button?.isEnabled = isCredenticalsValid
                        }
                        .store(in: &subscriptions)
                }
                .onTap {
                    Task {
                        try await self.viewModel.login()
                    }
                }
                .padding(.init(only: .bottom, inset: 16))
            UIButton(label: "Try SwiftUI", textColor: .blue)
                .onTap {
                    let vc = UIHostingController(rootView: LoginView(viewModel: .init()))
                    self.present(vc, animated: true)
                }
            UIView()
        }
    }
}
