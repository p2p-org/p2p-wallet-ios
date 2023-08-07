import Foundation

protocol RendableListOfframItem: Identifiable {
    var id: String { get }

    var status: RendableListOfframStatus { get }

    var title: String { get }

    var subtitle: String { get }

    var detail: String { get }

    var onTap: (() -> Void)? { get }
}

enum RendableListOfframStatus {
    case ready
    case error
}
