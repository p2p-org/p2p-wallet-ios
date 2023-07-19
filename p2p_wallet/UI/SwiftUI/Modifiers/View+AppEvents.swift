import SwiftUI

extension View {
    #if os(iOS)
        func onForeground(_ f: @escaping () -> Void) -> some View {
            onReceive(
                NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification),
                perform: { _ in f() }
            )
        }
    #else
        func onBackground(_ f: @escaping () -> Void) -> some View {
            onReceive(
                NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification),
                perform: { _ in f() }
            )
        }

        func onForeground(_ f: @escaping () -> Void) -> some View {
            onReceive(
                NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification),
                perform: { _ in f() }
            )
        }
    #endif
}
