import SwiftUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
        VStack {
            Text("Sell View")
            if viewModel.isLoading {
                loading
            }
        }
        
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
