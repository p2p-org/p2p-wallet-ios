import SwiftUI

extension View {
    func keyAppNavigationBar(title: String, onBack: (() -> Void)? = nil) -> some View {
        navigationBarTitle(title, displayMode: .inline)
            // .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: onBack != nil ? Button(
                        action: { onBack?() },
                        label: {
                            Image(.arrowBackIos)
                                .foregroundColor(Color(.night))
                        }
                    ) : nil
                )
    }
}
