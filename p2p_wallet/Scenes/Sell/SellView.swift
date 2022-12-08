import SwiftUI
import KeyAppUI

struct SellView: View {
    @ObservedObject var viewModel: SellViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
            VStack {
                if viewModel.isLoading {
                    loading
                } else {
                    form
                        .padding(.horizontal, 16)
                    Button {
                        viewModel.sell()
                    } label: {
                        Text("Sell")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) { Text("Sell SOL").fontWeight(.semibold) }
        }
    }

    var form: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Button {
                    viewModel.sellAll()
                } label: {
                    Text(viewModel.sellAllText)
                }
                TextField("Text", text: $viewModel.cryptoAmount)
            }
            TextField("Text2", text: $viewModel.cryptoAmount)
            VStack {
                Text("Result View")
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
