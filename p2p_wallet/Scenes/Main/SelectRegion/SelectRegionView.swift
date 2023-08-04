import KeyAppUI
import SwiftUI

struct SelectRegionView: View {
    @ObservedObject var viewModel: SelectRegionViewModel

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.top, 6)
            Spacer()
            list
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
        .edgesIgnoringSafeArea(.all)
    }

    var list: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items, id: \.id) { item in
                AnyRenderable(item: item)
                    .onTapGesture {
                        viewModel.itemTapped(item: item)
                    }
            }
        }
    }
}

struct SelectRegionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectRegionView(viewModel: .init())
    }
}
