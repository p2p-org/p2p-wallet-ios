import Combine
import SwiftUI

struct OnboardingBrokenScreen<CustomActions: View>: View {
    let title: String
    let contentData: OnboardingContentData

    let back: (() async throws -> Void)?

    @ViewBuilder var customActions: CustomActions

    @State var loading: Bool = false

    init(
        title: String,
        contentData: OnboardingContentData,
        back: (() async throws -> Void)? = nil,
        @ViewBuilder customActions: () -> CustomActions
    ) {
        self.title = title
        self.contentData = contentData
        self.back = back
        self.customActions = customActions()
    }

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: contentData
            )
            .padding(.top, 60)
            .padding(.bottom, 48)
            BottomActionContainer {
                VStack {
                    customActions

                    if let back = back {
                        TextButtonView(
                            title: L10n.startingScreen,
                            style: .ghostLime,
                            size: .large,
                            onPressed: {
                                Task {
                                    guard loading == false else { return }
                                    loading = true
                                    defer { loading = false }

                                    try await back()
                                }
                            }
                        )
                        .frame(height: TextButton.Size.large.height)
                    }
                }
            }
        }
        .onboardingNavigationBar(
            title: title,
            onBack: nil
        )
        .modifier(OnboardingScreen())
    }
}

extension OnboardingBrokenScreen where CustomActions == SwiftUI.EmptyView {
    init(
        title: String,
        contentData: OnboardingContentData,
        back: (() async throws -> Void)? = nil,
        help _: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            contentData: contentData,
            back: back,
            customActions: { SwiftUI.EmptyView() }
        )
    }
}

struct OnboardingBrokenScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnboardingBrokenScreen(
                title: L10n.restore,
                contentData: .init(
                    image: .easyToStart,
                    title: L10n.easyToStart,
                    subtitle: L10n.createYourAccountIn1Minute
                ),
                back: {}
            )
        }
    }
}
