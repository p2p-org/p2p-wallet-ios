//
//  DebugAppDelegateService.swift
//  p2p_wallet
//
//  Created by Babich Ivan on 16.06.2022.
//

#if !RELEASE
    import CocoaDebug

    final class DebugAppDelegateService: NSObject, AppDelegateService {
        func applicationDidFinishLaunching(_: UIApplication) {
            CocoaDebugSettings.shared.responseShake = false
            showDebugger(isShown)
        }
    }
#endif

#if !RELEASE
    var isShown = CocoaDebugSettings.shared.showBubbleAndWindow
#else
    var isShown = false
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

            isShown.toggle()
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
    }
#endif
