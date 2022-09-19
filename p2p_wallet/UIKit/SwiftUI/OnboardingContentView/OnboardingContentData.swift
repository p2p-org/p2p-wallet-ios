struct OnboardingContentData: Identifiable, Equatable {
    var id: String { title }
    let image: UIImage?
    let title: String
    let email: String?
    let subtitle: String?

    init(image: UIImage, title: String, email: String? = nil, subtitle: String? = nil) {
        self.image = image
        self.title = title
        self.email = email
        self.subtitle = subtitle
    }
}
