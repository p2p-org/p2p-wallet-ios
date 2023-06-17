//

import SwiftUI

struct AuthenticationPincodeView: View {
    @ObservedObject var viewModel: AuthenticationPincodeViewModel
    
    var body: some View {
        VStack {
            TextField("Pin code", text: $viewModel.pincode)
            Button("Verify") {
                viewModel.verify()
            }
        }
    }
}

//struct AuthPincodeView_Previews: PreviewProvider {
//    static var previews: some View {
//        AuthPincodeView()
//    }
//}
