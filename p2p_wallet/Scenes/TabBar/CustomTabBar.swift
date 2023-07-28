import Combine
import KeyAppUI
import UIKit

final class CustomTabBar: UITabBar {
    private lazy var middleButton: UIButton! = {
        let middleButton = UIButton()
        middleButton.frame.size = CGSize(width: 60, height: 60)
        middleButton.backgroundColor = Asset.Colors.snow.color
        middleButton.layer.cornerRadius = 30
        middleButton.setImage(.tabBarSend, for: .normal)
        middleButton.setImage(.tabBarSend, for: .highlighted)
        middleButton.imageView?.contentMode = .scaleAspectFit
        middleButton.contentHorizontalAlignment = .fill
        middleButton.contentVerticalAlignment = .fill
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        addSubview(middleButton)
        return middleButton
    }()

    private lazy var selectedView: UIView! = {
        let selectedView = UIView()
        selectedView.frame.size = CGSize(width: 36, height: 4)
        selectedView.layer.cornerRadius = 2
        selectedView.backgroundColor = Asset.Colors.lime.color
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

    private let middleButtonClickedSubject = PassthroughSubject<Void, Never>()
    var middleButtonClicked: AnyPublisher<Void, Never> { middleButtonClickedSubject.eraseToAnyPublisher() }

    override func layoutSubviews() {
        super.layoutSubviews()

        middleButton.center = CGPoint(
            x: frame.width / 2,
            y: frame.height / 2 - Self.additionalHeight - inset
        )
        updateSelectedViewPositionIfNeeded()

        layer.shadowColor = UIColor(red: 0.043, green: 0.122, blue: 0.208, alpha: 0.1).cgColor
        layer.shadowOffset = CGSize(width: 9, height: 22)
        layer.shadowRadius = 128
        layer.shadowOpacity = 1
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height += Self.additionalHeight
        return size
    }

    // MARK: - Actions

    @objc func middleButtonAction() {
        middleButtonClickedSubject.send()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds, !isHidden, alpha > 0 else { return nil }
        return middleButton.frame.contains(point) ? middleButton : super.hitTest(point, with: event)
    }

    func updateSelectedViewPositionIfNeeded() {
        guard let currentIndex = currentIndex else { return }
        let buttons = subviews.compactMap { NSStringFromClass(type(of: $0)) == "UITabBarButton" ? $0 : nil }
            .sorted(by: { $0.center.x < $1.center.x })

        guard currentIndex < buttons.count else { return }
        selectedView.center = CGPoint(x: buttons[currentIndex].center.x, y: 0)
    }
}
