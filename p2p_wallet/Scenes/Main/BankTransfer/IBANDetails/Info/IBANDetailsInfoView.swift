import Combine
import KeyAppUI
import SwiftUI

struct IBANDetailsInfoView: View {
    @ObservedObject var viewModel: IBANDetailsInfoViewModel

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
            Text(L10n.topUpYourAccount)
                .fontWeight(.semibold)
                .apply(style: .title3)
                .padding(.top, 22)
                .padding(.bottom, 20)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
    }
}

struct IBANDetailsInfoView_Previews: PreviewProvider {
    static var previews: some View {
        IBANDetailsInfoView(viewModel: IBANDetailsInfoViewModel())
    }
}
