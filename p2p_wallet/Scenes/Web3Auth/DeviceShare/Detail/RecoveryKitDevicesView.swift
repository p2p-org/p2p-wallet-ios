import KeyAppUI
import SwiftUI

struct RecoveryKitDevicesView: View {
    @ObservedObject var viewModel: RecoveryKitDevicesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.weVeNoticedThatYouReUsingANewDevice)
                        .apply(style: .text3)
                    Text(L10n
                        .forSecurityChangeYourAuthorizationDeviceToRestoreAccessIfNeeded)
                        .apply(style: .text3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                VStack {
                    VStack(spacing: 4) {
                        VStack(alignment: .leading) {
                            Text(L10n.thisDevice.uppercased())
                                .apply(style: .caps)
                                .foregroundColor(Color(.mountain))
                                .padding(.leading, 16)

                            HStack {
                                Image(.deviceIcon)
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 16)
                                Text(viewModel.currentDevice)
                                    .fontWeight(.semibold)
                                    .apply(style: .text3)
                                Spacer()
                                NewTextButton(title: L10n.setUp, size: .small, style: .second) {
                                    viewModel.setup()
                                }
                            }
                            .padding(.trailing, 16)
                            .foregroundColor(Color(.night))
                            .background(Color(.snow))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.rain), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 40)
                    Spacer()

                    VStack(spacing: 4) {
                        VStack(alignment: .leading) {
                            Text("Authorization device".uppercased())
                                .apply(style: .caps)
                                .foregroundColor(Color(.mountain))
                                .padding(.leading, 16)

                            HStack {
                                Image(.deviceIcon)
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 16)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.oldDevice)
                                        .fontWeight(.semibold)
                                        .apply(style: .text3)
                                        .padding(.top, 16)
                                    HStack(spacing: 4) {
                                        Image(.warningIcon)
                                            .foregroundColor(Color(.rose))
                                        Text(L10n.makeSureThisIsStillYourDevice)
                                            .fontWeight(.regular)
                                            .apply(style: .label1)
                                            .foregroundColor(Color(.rose))
                                    }
                                    .padding(.bottom, 12)
                                }
                                Spacer()
                            }
                            .padding(.trailing, 16)
                            .foregroundColor(Color(.night))
                            .background(Color(.snow))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.rain), lineWidth: 1)
                            )
                            Text(L10n.attentionIfYouUpdateYourCurrentDeviceYouWillNotBeAbleToUseTheOldDeviceForRecovery)
                                .apply(style: .label1)
                                .foregroundColor(Color(.mountain))
                                .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 28)
                }
            }
        }
        .background(
            Color(.smoke)
                .ignoresSafeArea()
        )
    }
}

struct RecoveryKitChangeDeviceShareView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryKitDevicesView(viewModel: .init())
    }
}
