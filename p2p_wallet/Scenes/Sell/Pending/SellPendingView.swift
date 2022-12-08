import SwiftUI

struct SellPendingView: View {

    @ObservedObject var viewModel = SellPendingViewModel()

    var body: some View {
        VStack {
            Text("Send SOL")
            Button {
                viewModel.send()
            } label: {
                Text("Send")
            }
            Button {
                viewModel.forget()
            } label: {
                Text("Forget")
            }
        }
    }

}
