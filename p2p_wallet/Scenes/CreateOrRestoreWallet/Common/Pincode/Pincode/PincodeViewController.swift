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
        setupNavBar()
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

                PinCode(correctPincode: viewModel.pincode, bottomLeftButton: nil)
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

        viewModel.$snackbar.sink { [weak self] model in
            guard let self = self, let model = model else { return }
            let view: UIView = self.navigationController?.view ?? self.view
            SnackBar(text: model.message).show(in: view, autoHide: true) {
                guard model.isFailure else { return }
                self.pincodeView.view?.reset()
            }
            self.viewModel.snackbar = nil
        }.store(in: &subscriptions)
    }

    private func setupNavBar() {
        addLeftButton()
        addRightButton()
    }

    private func addLeftButton() {
        guard viewModel.isBackAvailable else { return }
        let backButton = UIBarButtonItem(
            image: Asset.MaterialIcon.arrowBackIos.image,
            style: .plain,
            target: self,
            action: #selector(onBack)
        )
        backButton.tintColor = Asset.Colors.night.color
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func onBack() {
        viewModel.back.send()
    }

    private func addRightButton() {
        let infoButton = UIButton()
        infoButton.addTarget(self, action: #selector(openInfo), for: .touchUpInside)
        infoButton.setImage(Asset.MaterialIcon.helpOutline.image, for: .normal)
        infoButton.contentMode = .scaleAspectFill
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
    }

    @objc private func openInfo() {
        viewModel.infoDidTap.send()
    }
}
