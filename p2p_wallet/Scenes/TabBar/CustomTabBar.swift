import Combine
import UIKit

final class CustomTabBar: UITabBar {
    private lazy var selectedView: UIView! = {
        let selectedView = UIView()
        selectedView.frame.size = CGSize(width: 36, height: 4)
        selectedView.layer.cornerRadius = 2
        selectedView.backgroundColor = .init(resource: .lime)
        addSubview(selectedView)
        return selectedView
    }()

    var currentIndex: Int? {
        guard let item = selectedItem else { return nil }
        return items?.firstIndex(of: item)
    }

    static var additionalHeight: CGFloat = 8

    private var inset: CGFloat {
        if SafeAreaInsetsKey.defaultValue.bottom > 0 {
            return SafeAreaInsetsKey.defaultValue.bottom - 5
        }
        return 14
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateSelectedViewPositionIfNeeded()

        layer.shadowColor = UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 1
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height += Self.additionalHeight
        return size
    }

    override func draw(_: CGRect) {
        // Create a rounded rect path
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 16, height: 16)
        )

        // Set the fill color
        UIColor(resource: .snow).setFill()
        path.fill()
    }

    // MARK: - Actions

    func updateSelectedViewPositionIfNeeded() {
        guard let currentIndex = currentIndex else { return }
        let buttons = subviews.compactMap { NSStringFromClass(type(of: $0)) == "UITabBarButton" ? $0 : nil }
            .sorted(by: { $0.center.x < $1.center.x })

        guard currentIndex < buttons.count else { return }
        selectedView.center = CGPoint(x: buttons[currentIndex].center.x, y: 0)
    }
}
