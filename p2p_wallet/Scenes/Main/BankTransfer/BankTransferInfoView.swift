import SwiftUI

struct BankTransferInfoView: View {
    @ObservedObject var viewModel: BankTransferInfoViewModel

    var body: some View {
        ZStack {
            Color(UIColor.f2F5Fa)
                .edgesIgnoringSafeArea(.all)
            VStack {
                VStack(spacing: 28) {
                    list
                    Spacer()
                }
                .padding(.top, 20)
                Spacer()
            }
        }
    }
    
    var list: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items, id: \.id) { item in
                AnyRenderable(item: item)
                    .onTapGesture {
//                        viewModel.itemTapped(item)
                    }
            }
            .padding(.horizontal, 16)
        }
    }
    
}

struct BankTransferInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BankTransferInfoView(viewModel: .init())
    }
}
