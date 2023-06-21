import UIKit

struct ChooseRestoreOptionButton {
    let option: RestoreOption
    let title: String
    let icon: UIImage?

    init(option: RestoreOption, title: String, icon: UIImage? = nil) {
        self.option = option
        self.title = title
        self.icon = icon
    }
}
