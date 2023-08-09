import Foundation

struct RendableMockAccount: RenderableAccount {
    typealias SortingKey = Any

    var id: String

    var icon: AccountIcon

    var wrapped: Bool

    var title: String

    var subtitle: String

    var detail: AccountDetail

    var extraAction: AccountExtraAction?

    var tags: AccountTags
}
