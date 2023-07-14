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
                        Image(uiImage: Asset.MaterialIcon.arrowBackIos.image)
                            .foregroundColor(Color(.night))
                    }
                ) : nil,
                trailing: onInfo != nil ? Button(
                    action: { onInfo?() },
                    label: {
                        Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                            .foregroundColor(Color(.night))
                    }
                ) : nil
            )
    }
}
