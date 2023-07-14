import KeyAppUI
import SwiftUI

extension View {
    func onboardingNavigationBar(
        title: String,
        onBack: (() -> Void)? = nil,
        onInfo: (() -> Void)? = nil
    ) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: onBack != nil ? Button(
                    action: { onBack?() },
                    label: {
                        Image(.arrowBackIos)
                            .foregroundColor(Color(.night))
                    }
                ) : nil,
                trailing: onInfo != nil ? Button(
                    action: { onInfo?() },
                    label: {
                        Image(.helpOutline)
                            .foregroundColor(Color(.night))
                    }
                ) : nil
            )
    }
}
