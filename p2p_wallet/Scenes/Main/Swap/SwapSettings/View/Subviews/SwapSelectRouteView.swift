import SwiftUI
import KeyAppUI

struct SwapSelectRouteView<Route: SwapSettingsRouteInfo>: View {
    let routes: [Route]
    @Binding var selectedRoute: Route
    
    var body: some View {
        VStack {
            Text(L10n.swappingThrough)
                .fontWeight(.semibold)
                .apply(style: .text3)
                .padding(.horizontal, 40)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            LazyVStack {
                ForEach(routes) { route in
                    routeCell(route: route)
                    Divider()
                        .padding(.leading, 24)
                }
            }
        }
    }
    
    func routeCell(route: Route) -> some View {
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
            if selectedRoute.id == route.id {
                Image(systemName: "checkmark")
            }
        }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onTapGesture {
                selectedRoute = route
            }
    }
}

struct SwapSelectRouteView_Previews: PreviewProvider {
    static var previews: some View {
        SwapSelectRouteView(
            routes: [
                MockRouteInfo(
                    id: "1",
                    name: "Raydium",
                    description: "Best price",
                    tokens: "SOL→CLMM→USDC→CRAY"
                ),
                MockRouteInfo(
                    name: "Raydium 95% + Orca 5%",
                    description: "-0.0006 TokenB",
                    tokens: "SOL→CLMM→USDC→CRAY"
                ),
                MockRouteInfo(
                    name: "Raydium 95% + Orca 5%",
                    description: "-0.0006 TokenB",
                    tokens: "SOL→CLMM→USDC→CRAY"
                )
            ],
            selectedRoute: .constant(MockRouteInfo(
                id: "1",
                name: "Raydium",
                description: "Best price",
                tokens: "SOL→CLMM→USDC→CRAY"
            ))
        )
    }
}
