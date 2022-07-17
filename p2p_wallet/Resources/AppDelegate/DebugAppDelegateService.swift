//
//  DebugAppDelegateService.swift
//  p2p_wallet
//
//  Created by Babich Ivan on 16.06.2022.
//

#if !RELEASE

    /* script_delete_flag_start */
    import CocoaDebug
    /* script_delete_flag_end */

    final class DebugAppDelegateService: NSObject, AppDelegateService {
        func applicationDidFinishLaunching(_: UIApplication) {
            /* script_delete_flag_start */
            CocoaDebugSettings.shared.responseShake = false
            /* script_delete_flag_end */
            showDebugger(isShown)
        }
    }

#endif

#if !RELEASE

    var isShown = CocoaDebugSettings.shared.showBubbleAndWindow

#endif

/* script_delete_flag_start */
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
/* script_delete_flag_end */

#if !RELEASE

    func showDebugger(_ isShown: Bool) {
        DispatchQueue.main.async {
            /* script_delete_flag_start */
            if isShown {
                CocoaDebug.showBubble()
            } else {
                CocoaDebug.hideBubble()
            }
            /* script_delete_flag_end */
        }
    }

#endif
