struct OnboardingContentData: Identifiable {
    var id: String { title }
    let image: UIImage?
    let title: String
    let subtitle: String?

    init(image: UIImage, title: String, subtitle: String? = nil) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
}
