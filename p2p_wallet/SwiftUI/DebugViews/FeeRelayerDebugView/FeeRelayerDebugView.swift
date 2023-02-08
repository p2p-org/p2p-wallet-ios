import SwiftUI
import FeeRelayerSwift
import Resolver

struct FeeRelayerDebugView: View {
    @ObservedObject var viewModel: FeeRelayerDebugViewModel
    
    var body: some View {
        Text(viewModel.calculationDebugText)
            .font(uiFont: .font(of: .label2, weight: .regular))
            .foregroundColor(Color(.red))
            .multilineTextAlignment(.trailing)
    }
}

//struct FeeRelayerDebugView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeeRelayerDebugView()
//    }
//}
