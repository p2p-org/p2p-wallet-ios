import Combine

enum TermsAndPolicyType: String {
    case termsOfService = "Terms_of_service"
    case privacyPolicy = "Privacy_policy"
}

final class TermsAndPolicyCoordinator: Coordinator<Void> {
    private var subject = PassthroughSubject<Void, Never>()
    private let parentController: UIViewController
    private let docType: TermsAndPolicyType

    init(parentController: UIViewController, docType: TermsAndPolicyType) {
        self.parentController = parentController
        self.docType = docType
    }

    override func start() -> AnyPublisher<Void, Never> {
        let vc = WLMarkdownVC(
            title: self.title(),
            bundledMarkdownTxtFileName: docType.rawValue
        )
        parentController.present(vc, animated: true)
        vc.presentationController?.delegate = self
        return subject.eraseToAnyPublisher()
    }

    private func title() -> String {
        switch docType {
        case .termsOfService:
            return L10n.termsOfService
        case .privacyPolicy:
            return L10n.privacyPolicy
        }
    }
}

extension TermsAndPolicyCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        subject.send(completion: .finished)
    }
}
