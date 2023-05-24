import SwiftUI
import KeyAppUI

struct BankTransferInfoView: View {
    @ObservedObject var viewModel: BankTransferInfoViewModel

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
                list
                    .padding(.top, 20)
                Spacer()
            
        }
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
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
