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

            Text(L10n.importantNotes)
                .fontWeight(.semibold)
                .apply(style: .title3)
                .padding(.top, 12)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                infoItem(
                    text: L10n.useThisIBANToSendMoneyFromYourPersonalAccounts,
                    icon: .user
                )
                Rectangle()
                    .frame(height: 1)
                    .padding(.leading, 20)
                    .foregroundColor(Color(asset: Asset.Colors.rain))
                infoItem(
                    text: L10n.yourBankAccountNameMustMatchTheNameOfYourKeyAppAccount,
                    icon: .buyBank
                )
            }

            HStack(spacing: 12) {
                CheckboxView(isChecked: $viewModel.isChecked)

                Text(L10n.donTShowMeAgain)
                    .apply(style: .text3)
                    .foregroundColor(Color(asset: Asset.Colors.night))

                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            NewTextButton(title: L10n.gotIt, style: .second, expandable: true, action: viewModel.close.send)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 28)
        .frame(minHeight: 64)
    }
}

struct IBANDetailsInfoView_Previews: PreviewProvider {
    static var previews: some View {
        IBANDetailsInfoView(viewModel: IBANDetailsInfoViewModel())
    }
}
