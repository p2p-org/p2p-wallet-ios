import SwiftUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
//        switch viewModel.state {
//        case .loading:
//            loading
//        case .pending:
//            pending
//        case .sell:
//            sell
//        }
        Text("Sell View")
    }

    var loading: some View {
        ProgressView()
    }

    var pending: some View {
        Text("Pending")
    }

    var sell: some View {
        Text("Sell")
    }

}
