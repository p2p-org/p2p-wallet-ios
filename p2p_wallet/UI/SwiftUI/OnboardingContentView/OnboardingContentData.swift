import Foundation

struct OnboardingContentData: Identifiable, Equatable {
    struct Subtitle: Identifiable, Equatable {
        var id: String { text }
        let text: String
        let isLimited: Bool

        init(text: String, isLimited: Bool = false) {
            self.text = text
            self.isLimited = isLimited
        }
    }

    var id: String { title }
    let image: ImageResource
    let title: String
    let subtitles: [Subtitle]

    init(image: ImageResource, title: String, subtitles: [Subtitle] = []) {
        self.image = image
        self.title = title
        self.subtitles = subtitles
    }

    init(image: ImageResource, title: String, subtitle: String) {
        self.image = image
        self.title = title
        subtitles = [Subtitle(text: subtitle, isLimited: false)]
    }
}
