import BEPureLayout
import Foundation
import UIKit

class WLMarkdownVC: WLIndicatorModalVC, CustomPresentableViewController {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }

    var transitionManager: UIViewControllerTransitioningDelegate?
    private let fileName: String
    private lazy var markdownView = WLMarkdownView(bundledMarkdownTxtFileName: fileName)

    init(title: String, bundledMarkdownTxtFileName: String) {
        fileName = bundledMarkdownTxtFileName
        super.init()
        self.title = title
    }

    override func setUp() {
        super.setUp()

        // stack view
        let stackView = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill) {
            UILabel(text: title, textSize: 21, weight: .medium)
                .padding(.init(x: 20, y: 0))
            UIView.separator(height: 1, color: .separator)
            BEStackViewSpacing(0)
            markdownView
        }
        containerView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))

        markdownView.load()
    }

    func calculateFittingHeightForPresentedView(targetWidth _: CGFloat) -> CGFloat {
        .greatestFiniteMagnitude
    }

    var dismissalHandlingScrollView: UIScrollView? {
        markdownView.scrollView
    }
}

class WLIndicatorModalVC: BaseVC {
    lazy var containerView = UIView(backgroundColor: .init(resource: .grayMain))
    var swipeGesture: UIGestureRecognizer?

    // MARK: - Initializers

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.roundCorners([.topLeft, .topRight], radius: 20)
    }

    override func setUp() {
        super.setUp()
        view.backgroundColor = .clear
        let topGestureView = UIView(width: 71, height: 5, backgroundColor: .init(resource: .indicator), cornerRadius: 2.5)
        view.addSubview(topGestureView)
        topGestureView.autoPinEdge(toSuperviewSafeArea: .top)
        topGestureView.autoAlignAxis(toSuperviewAxis: .vertical)

        view.addSubview(containerView)
        containerView.autoPinEdge(.top, to: .bottom, of: topGestureView, withOffset: 8)
        containerView.autoPinEdge(toSuperviewSafeArea: .leading)
        containerView.autoPinEdge(toSuperviewSafeArea: .trailing)
        containerView.autoPinEdge(toSuperviewEdge: .bottom)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        containerView.addGestureRecognizer(tapGesture)

        if modalPresentationStyle == .custom {
            swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDidSwipe(_:)))
            view.addGestureRecognizer(swipeGesture!)
            view.isUserInteractionEnabled = true
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func viewDidSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
        (presentationController as? ResizablePresentationController)?
            .presentedViewDidSwipe(gestureRecognizer: gestureRecognizer)
    }
}
