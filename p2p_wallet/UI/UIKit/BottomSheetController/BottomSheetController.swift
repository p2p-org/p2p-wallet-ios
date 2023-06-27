import UIKit
import SwiftUI
import KeyAppUI

struct ModalView<Content: View>: View {
    let showHandler: Bool
    let content: Content
    let title: String?

    init(title: String? = nil, showHandler: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showHandler = showHandler
        self.content = content()
    }

    var body: some View {
        VStack(spacing: .zero) {
            if showHandler {
                RoundedRectangle(cornerRadius: 2, style: .circular)
                    .fill(Color(Asset.Colors.silver.color))
                    .frame(width: 31, height: 4)
                    .padding(.top, 6)
            }
            if let title {
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .text1)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
            }
            content
            Spacer()
        }
            .edgesIgnoringSafeArea(.all)
    }
}

class BottomSheetController<Content: View>: UIHostingController<ModalView<Content>> {

    @MainActor public init(title: String? = nil, showHandler: Bool = false, rootView: Content) {
        super.init(rootView: ModalView(title: title, showHandler: showHandler) { rootView })
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum PreferredSheetSizing: CGFloat {
        case fit = 0 // Fit, based on the view's constraints
        case small = 0.25
        case medium = 0.5
        case large = 0.75
        case fill = 1
    }

    private lazy var bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
        preferredSheetTopInset: preferredSheetTopInset,
        preferredSheetCornerRadius: preferredSheetCornerRadius,
        preferredSheetSizingFactor: preferredSheetSizing.rawValue,
        preferredSheetBackdropColor: preferredSheetBackdropColor
    )

    override var additionalSafeAreaInsets: UIEdgeInsets {
        get {
            .init(
                top: super.additionalSafeAreaInsets.top,
                left: super.additionalSafeAreaInsets.left,
                bottom: super.additionalSafeAreaInsets.bottom,
                right: super.additionalSafeAreaInsets.right
            )
        }
        set {
            super.additionalSafeAreaInsets = newValue
        }
    }

    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            .custom
        }
        set { }
    }

    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            bottomSheetTransitioningDelegate
        }
        set { }
    }

    var preferredSheetTopInset: CGFloat = 0 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetTopInset = preferredSheetTopInset
        }
    }

    var preferredSheetCornerRadius: CGFloat = 20 {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetCornerRadius = preferredSheetCornerRadius
        }
    }

    var preferredSheetSizing: PreferredSheetSizing = .medium {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetSizingFactor = preferredSheetSizing.rawValue
        }
    }

    var preferredSheetBackdropColor: UIColor = .label {
        didSet {
            bottomSheetTransitioningDelegate.preferredSheetBackdropColor = preferredSheetBackdropColor
        }
    }

    var tapToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.tapToDismissEnabled = tapToDismissEnabled
        }
    }

    var panToDismissEnabled: Bool = true {
        didSet {
            bottomSheetTransitioningDelegate.panToDismissEnabled = panToDismissEnabled
        }
    }
}
