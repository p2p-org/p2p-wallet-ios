import SwiftUI
import KeyAppUI
import Combine
import SkeletonUI

struct SwapSelectRouteView: View {
    
    // MARK: - Nested type

    enum Status: Equatable {
        case loading
        case loaded(routeInfos: [SwapSettingsRouteInfo], selectedIndex: Int?)
    }

    // MARK: - Properties

    let statusPublisher: AnyPublisher<Status, Never>
    let onTapDone: (SwapSettingsRouteInfo) -> Void
    
    @State private var isLoading = false
    @State private var routes: [SwapSettingsRouteInfo] = []
    @State private var selectedIndex: Int?
    
    var body: some View {
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
            
            if isLoading {
                ForEach(0..<3) { _ in
                    routeCell(route: .init(name: "Placeholder", description: "Placeholder", tokensChain: "Placeholder"), isSelected: false)
                }
            } else {
                LazyVStack {
                    ForEach(Array(zip(routes.indices, routes)), id: \.0) { index, route in
                        routeCell(route: route, isSelected: index == selectedIndex)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedIndex = index
                            }
                        
                        if index != routes.count - 1 {
                            Divider()
                                .padding(.leading, 24)
                        }
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
                .padding(.bottom, 20)

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
            .onReceive(statusPublisher) { status in
                switch status {
                case .loading:
                    self.isLoading = true
                case let .loaded(routeInfos, selectedIndex):
                    self.isLoading = false
                    self.routes = routeInfos
                    self.selectedIndex = selectedIndex
                }
            }
    }
    
    func routeCell(route: SwapSettingsRouteInfo, isSelected: Bool) -> some View {
        HStack {
            // info
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .apply(style: .text3)
                    .skeleton(with: isLoading, size: .init(width: 52, height: 16))
                Text(route.description)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .skeleton(with: isLoading, size: .init(width: 100, height: 12))
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
    static var subject = CurrentValueSubject<SwapSelectRouteView.Status, Never>(.loading)
    static var previews: some View {
        SwapSelectRouteView(
            statusPublisher: subject.eraseToAnyPublisher(),
            onTapDone: {_ in }
        )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    subject.send(.loaded(
                        routeInfos: [
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
                    ))
                }
            }
    }
}
