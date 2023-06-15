import KeyAppUI
import SwiftUI
import Kingfisher

struct ReceiveView: View {
    @ObservedObject var viewModel: ReceiveViewModel
    let iconSize = CGFloat(36.0)

    var body: some View {
        ZStack {
            Color(UIColor.f2F5Fa)
                .edgesIgnoringSafeArea(.all)
            VStack {
                ScrollView {
                    VStack(spacing: 28) {
                        qr
                        list
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                .scrollOnlyOnOverflow()
                Spacer()
                TextButtonView(
                    title: L10n.copyAddress,
                    style: .primaryWhite,
                    size: .large,
                    trailing: UIImage.transactionsCopy.withTintColor(Asset.Colors.snow.color),
                    onPressed: {
                        viewModel.buttonTapped()
                    }
                )
                .frame(height: TextButton.Size.large.height)
                .padding(.bottom, 36)
                .padding(.horizontal, 16)
            }
        }
    }

    var qr: some View {
        ZStack {
            Image(uiImage: viewModel.qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            if let centerImage = viewModel.qrCenterImage {
                Image(uiImage: centerImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(radius: iconSize / 2, corners: .allCorners)
            } else if let centerImageURL = viewModel.qrCenterImageURL {
                KFImage
                    .url(centerImageURL)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: iconSize * 2, height: iconSize * 2))
                        |> RoundCornerImageProcessor(cornerRadius: iconSize)
                    )
                    .placeholder {
                        placeholderIcon
                    }
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.25)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(radius: iconSize / 2, corners: .allCorners)
            }
        }
        .onTapGesture {
            viewModel.qrTapped()
        }
    }

    var list: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items, id: \.id) { item in
                AnyRendable(item: item)
                    .onTapGesture {
                        viewModel.itemTapped(item)
                    }
            }
            .padding(.horizontal, 16)
        }
    }

    var placeholderIcon: some View {
        Circle()
            .fill(Color(Asset.Colors.smoke.color))
            .overlay(
                Image(uiImage: .imageOutlineIcon)
                    .renderingMode(.template)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            )
            .clipped()
            .frame(width: iconSize, height: iconSize)
    }
}

// TODO: Refactor
//struct ReceiveView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReceiveView(viewModel: .init(ethAddress: "0x0ea9f413a9be5afcec51d1bc8fd20b29bef5709c", token: "USDC", qrCenterImage: UIImage.usdc))
//    }
//}
