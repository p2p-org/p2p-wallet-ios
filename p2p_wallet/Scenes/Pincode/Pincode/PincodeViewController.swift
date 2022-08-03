import Combine
import KeyAppUI
import UIKit

final class PincodeViewController: BaseViewController {
    private let viewModel: PincodeViewModel
    public var subscriptions = [AnyCancellable]()

    // MARK: - Subviews

    private var titleLabel = BERef<UILabel>()
    private var pincodeView = BERef<PinCode>()

    init(viewModel: PincodeViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pincodeView.view?.reset()
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = Asset.Colors.lime.color
        addRightButton()
    }

    override func build() -> UIView {
        BESafeArea {
            BEVStack {
                UIImageView(
                    width: 160,
                    height: 120,
                    image: UIImage.lockPincode,
                    contentMode: .scaleAspectFit
                )
                    .padding(.init(top: 24, left: .zero, bottom: 24, right: .zero))

                UILabel(
                    font: .font(of: .title2, weight: .regular),
                    textAlignment: .center
                )
                    .bind(titleLabel)

                UIView.spacer

                PinCode(correctPincode: viewModel.pincode, bottomLeftButton: makeBottomLeftButton())
                    .setup { view in
                        view.stackViewSpacing = 24
                    }
                    .bind(pincodeView)
            }
        }
    }

    override func bind() {
        super.bind()

        viewModel.$title.sink { [weak titleLabel] title in
            titleLabel?.text = title
        }.store(in: &subscriptions)

        pincodeView.onSuccess = { [weak viewModel] value in
            viewModel?.pincodeSuccess.send(value)
        }
        pincodeView.onFailed = { [weak viewModel] in
            viewModel?.pincodeFailed.send()
        }
        pincodeView.onFailedAndExceededMaxAttemps = { [weak viewModel] in
            viewModel?.pincodeFailedAndExceededMaxAttempts.send()
        }

        viewModel.$snackbar.sink { [weak self] snackbar in
            guard let self = self, let snackbar = snackbar else { return }
            SnackBar(icon: snackbar.image, text: snackbar.title).show(in: self, autoDismiss: true)
            self.viewModel.snackbar = nil
        }.store(in: &subscriptions)
    }

    private func addRightButton() {
        let infoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        infoButton.addTarget(self, action: #selector(openInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    @objc private func openInfo() {
        viewModel.infoDidTap.send()
    }

    private func makeBottomLeftButton() -> IconButton? {
        guard let image = viewModel.bioAuthStatus.icon, viewModel.isBiometryAvailable else { return nil }
        let button = IconButton(image: image, style: .ghostBlack, size: .large)
        button.onPressed { [weak viewModel] _ in
            viewModel?.bioAuthDidTap.send()
        }
        return button
    }
}
