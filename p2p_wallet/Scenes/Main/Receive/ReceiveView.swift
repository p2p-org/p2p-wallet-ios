import KeyAppUI
import SwiftUI

struct ReceiveView: View {
    @ObservedObject var viewModel: ReceiveViewModel

    var body: some View {
        ZStack {
            Color(UIColor.f2F5Fa)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 28) {
                qr
                list
                Spacer()
                TextButtonView(
                    title: L10n.copyAddress,
                    style: .primaryWhite,
                    size: .large,
                    onPressed: {
                        viewModel.buttonTapped()
                    }
                )
                .frame(height: TextButton.Size.large.height)
                .padding(.bottom, 36)
                .padding(.horizontal, 16)
            }
            .padding(.top, 20)
        }
    }

    var qr: some View {
        ZStack {
            Image(uiImage: viewModel.qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            if let center = viewModel.qrCenterImage {
                Image(uiImage: center)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
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
        }
        .padding(.horizontal, 16)
    }
}

struct ReceiveView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveView(viewModel: .init(ethAddress: "0x0ea9f413a9be5afcec51d1bc8fd20b29bef5709c", token: "USDC", qrCenterImage: UIImage.usdc))
    }
}
