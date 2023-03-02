import SwiftUI
import KeyAppUI

struct SwapSelectRouteView: View {
    @State var routes: [SwapSettingsRouteInfo]
    @State var selectedIndex: Int?
    let onTapDone: (SwapSettingsRouteInfo) -> Void
    
    var body: some View {
        if #available(iOS 15.0, *) {
            let _ = Self._printChanges()
        }
        VStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(Asset.Colors.rain.color))
                .frame(width: 31, height: 4)
                .padding(.vertical, 6)
            
            Text(L10n.swappingThrough)
                .fontWeight(.semibold)
                .apply(style: .title3)
                .padding(.horizontal, 40)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            LazyVStack {
                ForEach(Array(zip(routes.indices, routes)), id: \.0) { index, route in
                    routeCell(route: route, isSelected: index == selectedIndex)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIndex = index
                        }
                    
                    if index != routes.count - 1 {
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
            
            Text(L10n.done)
                .fontWeight(.semibold)
                .apply(style: .text2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(Asset.Colors.rain.color))
                )
                .onTapGesture {
                    guard let selectedIndex, selectedIndex < routes.count else { return }
                    onTapDone(routes[selectedIndex])
                }
                .padding(.horizontal, 16)

            // TextButtonView notwork with bottom sheet??
//            TextButtonView(
//                title: L10n.done,
//                style: .second,
//                size: .large,
//                onPressed: {

//                }
//            )
//                .frame(height: TextButton.Size.large.height)
//                .padding(.horizontal, 16)
        }
    }
    
    func routeCell(route: SwapSettingsRouteInfo, isSelected: Bool) -> some View {
        HStack {
            // info
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .apply(style: .text3)
                Text(route.description)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            
            Spacer()
            
            // check mark
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

struct SwapSelectRouteView_Previews: PreviewProvider {
    static var previews: some View {
        SwapSelectRouteView(
            routes: [
                .init(
                    id: "1",
                    name: "Raydium",
                    description: "Best price",
                    tokensChain: "SOL→CLMM→USDC→CRAY"
                ),
                .init(
                    name: "Raydium 95% + Orca 5%",
                    description: "-0.0006 TokenB",
                    tokensChain: "SOL→CLMM→USDC→CRAY"
                ),
                .init(
                    name: "Raydium 95% + Orca 5%",
                    description: "-0.0006 TokenB",
                    tokensChain: "SOL→CLMM→USDC→CRAY"
                )
            ],
            selectedIndex: 0
        ) {_ in }
    }
}
