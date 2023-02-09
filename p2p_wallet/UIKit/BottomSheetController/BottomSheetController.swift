import UIKit
import SwiftUI
import KeyAppUI

struct ModalView<Content: View>: View {
    let title: String?
    let content: Content
    let showHandler: Bool
    let backgroundColor: Color?
    let handlerColor: Color?
    var cornerRadius = 20.0

    init(
        title: String? = nil,
        backgroundColor: Color? = nil,
        handlerColor: Color? = nil,
        showHandler: Bool = true,
        cornerRadius: Double = 20.0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showHandler = showHandler
        self.backgroundColor = backgroundColor
        self.handlerColor = handlerColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(spacing: .zero) {
            if showHandler {
                Group {
                    if let handlerColor {
                        handlerColor
                            .frame(width: 31, height: 4)
                            .cornerRadius(2)
                    } else {
                        Color(Asset.Colors.rain.color)
                            .frame(width: 31, height: 4)
                            .cornerRadius(2)
                    }
                }
                    .frame(height: 16)
                    .padding(.top, 6)
            }
            if let title {
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .title3)
                    .padding(.top, 12)
            }
            content
        }
        .background(backgroundColor ?? Color(Asset.Colors.snow.color))
        .cornerRadius(cornerRadius)
        .edgesIgnoringSafeArea(.all)
    }
}

class BottomSheetController<Content: View>: UIHostingController<ModalView<Content>> {

    @MainActor public init(
        title: String? = nil,
        backgroundColor: Color? = nil,
        handlerColor: Color? = nil,
        cornerRadius: Double = 20.0,
        showHandler: Bool = true,
        rootView: Content
    ) {
        super.init(
            rootView:
                ModalView(
                    title: title,
                    backgroundColor: backgroundColor,
                    handlerColor: handlerColor,
                    cornerRadius: cornerRadius,
                    content: {
                        rootView
                    }
                )
        )
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
