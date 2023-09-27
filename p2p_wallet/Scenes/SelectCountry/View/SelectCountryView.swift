import SkeletonUI
import SwiftUI

struct SelectCountryView: View {
    @ObservedObject var viewModel: SelectCountryViewModel

    var body: some View {
        WrapperForSearchingView(searching: $viewModel.isSearching) {
            searchableContent
        }
        .searchable(text: $viewModel.searchText)
    }

    private var searchableContent: some View {
        Group {
            switch viewModel.state {
            case .loaded, .skeleton:
                content
            case .notFound:
                Spacer()
                notFoundView
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.selectYourCountry)
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            if viewModel.searchText.isEmpty {
                Section(header: Text(L10n.chosenCountry)) {
                    switch viewModel.state {
                    case .skeleton:
                        countrySkeleton
                    case .loaded:
                        Button(
                            action: {
                                viewModel.currentCountrySelected()
                            },
                            label: {
                                countryView(
                                    flag: viewModel.selectedCountry.flag,
                                    title: viewModel.selectedCountry.title
                                )
                            }
                        )
                    case .notFound:
                        SwiftUI.EmptyView()
                    }
                }
            }
            Section(header: Text(L10n.allCountries)) {
                switch viewModel.state {
                case .skeleton:
                    ForEach(0 ..< 10) { _ in
                        countrySkeleton
                    }
                case let .loaded(countries):
                    ForEach(0 ..< countries.count, id: \.self) { index in
                        Button(
                            action: {
                                viewModel.countrySelected(model: countries[index])
                            },
                            label: {
                                countryView(flag: countries[index].flag, title: countries[index].title)
                            }
                        )
                    }
                case .notFound:
                    SwiftUI.EmptyView()
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func countryView(flag: String, title: String) -> some View {
        HStack(spacing: 10) {
            Text(flag)
                .font(uiFont: .font(of: .title1, weight: .bold))
            Text(title)
                .foregroundColor(Color(.night))
                .font(uiFont: .font(of: .text3))
        }
        .padding(.vertical, 6)
    }

    private var countrySkeleton: some View {
        HStack(spacing: 12) {
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 32, height: 28),
                    animated: .default
                )
            Text("")
                .skeleton(
                    with: true,
                    size: CGSize(width: 120, height: 16),
                    animated: .default
                )
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Not Found

private extension SelectCountryView {
    var notFoundView: some View {
        VStack(spacing: 20) {
            Image(.womanNotFound)
            Text(L10n.sorryWeDonTKnowThatCountry)
                .foregroundColor(Color(.night))
                .font(uiFont: .font(of: .text3))
        }
    }
}
