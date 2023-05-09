import UIKit
import BEPureLayout

public final class SplashViewController: BEViewController {

    private let customView = SplashView()

    public override func setUp() {
        let wrapper = customView
            .centered(.horizontal)
            .centered(.vertical)
            .backgroundColor(color: Asset.Colors.lime.color)

        self.view.addSubview(wrapper)
        wrapper.autoPinEdgesToSuperviewEdges()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.run()
    }

    public func stop(completionHandler: @escaping (() -> Void)) {
        customView.completionHandler = completionHandler
        if customView.isStopped {
            completionHandler()
        }
    }

    private func run() {
        customView.animate()
    }

    @objc private func appMovedToBackground() {
        customView.stopAnimation()
        customView.completionHandler?()
    }
}
