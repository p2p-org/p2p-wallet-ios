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

            Text("Important notes")
                .fontWeight(.semibold)
                .apply(style: .title3)
                .padding(.top, 22)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                infoItem(
                    text: L10n.useThisIBANToSendMoneyFromYourPersonalAccounts,
                    icon: .user
                )
                Spacer()
                    .frame(height: 1)
                    .padding(.leading, 20)
                infoItem(
                    text: "Your bank account name must match the name of your Key App account",
                    icon: .buyBank
                )
            }

            CheckboxView(isChecked: $viewModel.isChecked)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
    }

    func infoItem(text: String, icon: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: icon)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(asset: Asset.Colors.night))
                .frame(width: 24, height: 24)

            Text(text)
                .apply(style: .text3)
                .foregroundColor(Color(asset: Asset.Colors.night))

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 64)
    }
}

struct IBANDetailsInfoView_Previews: PreviewProvider {
    static var previews: some View {
        IBANDetailsInfoView(viewModel: IBANDetailsInfoViewModel())
    }
}
