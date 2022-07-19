//
//  DebugAppDelegateService.swift
//  p2p_wallet
//
//  Created by Babich Ivan on 16.06.2022.
//

#if !RELEASE
    import CocoaDebug
    import UIKit

    private class DebugVC: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .yellow
        }
    }

    final class DebugAppDelegateService: NSObject, AppDelegateService {
        func application(
            _: UIApplication,
            didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
        ) -> Bool {
            CocoaDebugSettings.shared.responseShake = false
            CocoaDebugSettings.shared.enableLogMonitoring = true
            CocoaDebugSettings.shared.enableWKWebViewMonitoring = true
            CocoaDebugSettings.shared.additionalViewController = DebugVC()
            CocoaDebug.enable()

            showDebugger(isShown)
            return true
        }
    }
#endif

#if !RELEASE
    var isShown: Bool {
        CocoaDebugSettings.shared.showBubbleAndWindow
    }
#endif

#if !RELEASE
    var isShaken = false

    extension UIWindow {
        override open func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            super.motionBegan(motion, with: event)
            isShaken = true
        }

        override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            super.motionEnded(motion, with: event)
            guard isShaken else {
                isShaken.toggle()
                return
            }

            guard motion == .motionShake else { return }

            CocoaDebugSettings.shared.showBubbleAndWindow = !CocoaDebugSettings.shared.showBubbleAndWindow
            showDebugger(isShown)
        }
    }
#endif

#if !RELEASE
    func showDebugger(_ isShown: Bool) {
        DispatchQueue.main.async {
            if isShown {
                CocoaDebug.showBubble()
            } else {
                CocoaDebug.hideBubble()
            }
        }
        CocoaDebugSettings.shared.showBubbleAndWindow = isShown
    }
#endif
