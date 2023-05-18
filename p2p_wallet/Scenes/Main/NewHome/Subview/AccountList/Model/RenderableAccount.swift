import Foundation

protocol RenderableAccount: Identifiable where ID == String {
    var id: String { get }

    var icon: AccountIcon { get }

    var wrapped: Bool { get }

    var title: String { get }

    var subtitle: String { get }

    var detail: AccountDetail { get }

    var extraAction: AccountExtraAction? { get }

    var tags: AccountTags { get }
}

extension RenderableAccount {
    var isInIgnoreList: Bool {
        tags.contains(.ignore)
    }

    var onTapEnable: Bool {
        switch detail {
        case .button:
            return false
        default:
            return true
        }
    }
}

struct AccountTags: OptionSet {
    let rawValue: Int

    /// Account will be in favourite list. (Always display on top section)
    static let favourite = AccountTags(rawValue: 1 << 0)

    /// Account will be in ignore list. (Second section)
    static let ignore = AccountTags(rawValue: 1 << 1)
    
    /// Account will be hidden.
    static let hidden = AccountTags(rawValue: 1 << 2)
}

enum AccountExtraAction {
    case visiable
}

enum AccountDetail {
    case text(String)
    case button(label: String, enabled: Bool)
}

enum AccountIcon {
    case image(UIImage)
    case url(URL)
    case random(seed: String)
}
