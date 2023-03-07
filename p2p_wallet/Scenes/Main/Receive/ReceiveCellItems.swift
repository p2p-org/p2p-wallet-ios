import SwiftUI
import KeyAppUI

/// In case of successful experiment make a base Renderable protocol
protocol ReceiveCellViewRenderable {
    associatedtype ViewType: View
    @ViewBuilder func render() -> ViewType
}

protocol ReceiveCellItem: Hashable, Identifiable, ReceiveCellViewRenderable {}

/// Opaque type for cell views
struct AnyReceiveCellRenderableView: View {
    var item: any ReceiveCellItem

    init(item: any ReceiveCellItem) {
        self.item = item
    }

    var body: some View {
        AnyView(item.render())
    }
}

struct ListRowReceiveCellItem {
    var id: String
    var title: String
    var description: String
    var showTopCorners: Bool
    var showBottomCorners: Bool
}

extension ListRowReceiveCellItem: ReceiveCellItem {
    typealias ViewType = ListRowReceiveCellView
    func render() -> ViewType {
        ListRowReceiveCellView(item: self)
    }
}

struct ListDividerReceiveCellItem {
    var id: String = UUID().uuidString
}

extension ListDividerReceiveCellItem: ReceiveCellItem {
    typealias ViewType = ListDividerReceiveCellView
    func render() -> ViewType {
        ListDividerReceiveCellView()
    }
}

struct SpacerReceiveCellItem {
    var id: String = UUID().uuidString
}

extension SpacerReceiveCellItem: ReceiveCellItem {
    typealias ViewType = SpacerReceiveCellView

    func render() -> ViewType {
        SpacerReceiveCellView()
    }
}

struct RefundBannerReceiveCellItem {
    var id: String = UUID().uuidString
    let text: String
}

extension RefundBannerReceiveCellItem: ReceiveCellItem {
    typealias ViewType = RefundBannerReceiveCellView

    func render() -> ViewType {
        RefundBannerReceiveCellView(item: self)
    }
}

struct InstructionsReceiveCellItem {
    var id: String = UUID().uuidString
    let instructions: [(String, String)]
    let tip: String

    // MARK: -

    static func == (lhs: InstructionsReceiveCellItem, rhs: InstructionsReceiveCellItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tip)
    }
}

extension InstructionsReceiveCellItem: ReceiveCellItem {
    typealias ViewType = InstructionsReceiveCellView

    func render() -> ViewType {
        InstructionsReceiveCellView(item: self)
    }
}
