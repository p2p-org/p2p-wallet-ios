import PnLService
import Repository
import SwiftUI

struct PnLView<Content: View>: View {
    let pnlRepository: PnLRepository
    let skeletonSize: CGSize
    var content: (PnLModel?) -> Content

    init(
        pnlRepository: PnLRepository,
        skeletonSize: CGSize,
        @ViewBuilder content: @escaping (PnLModel?) -> Content
    ) {
        self.pnlRepository = pnlRepository
        self.skeletonSize = skeletonSize
        self.content = content
    }

    var body: some View {
        RepositoryView(
            repository: pnlRepository
        ) { pnl in
            content(pnl)
                .skeleton(with: pnl == nil, size: skeletonSize)
        } errorView: { _, pnl in
            // ignore error
            content(pnl)
        } content: { pnl in
            content(pnl)
        }
    }
}
