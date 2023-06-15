import SwiftUI
import KeyAppUI

struct ChoosePhoneCodeView: View {
    @ObservedObject private var viewModel: ChoosePhoneCodeViewModel

    init(viewModel: ChoosePhoneCodeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 20) {
                SearchField(
                    searchText: $viewModel.keyword,
                    isFocused: $viewModel.isSearchFieldFocused
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                WrappedList {
                    ForEach(viewModel.data) { item  in
                        ZStack(alignment: .bottom) {
                            ChoosePhoneCodeItemView(country: item)

                            // Separator added manually to support iOS 14 version
                            if viewModel.data.count > 1 && item.id != viewModel.data.last?.id {
                                Rectangle()
                                    .fill(Color(Asset.Colors.rain.color))
                                    .frame(height: 1)
                                    .padding(.leading, 20)
                            }
                        }
                        .frame(height: 68)
                        .onTapGesture {
                            viewModel.select(country: item)
                        }
                    }
                }
                .modifier(ListBackgroundModifier(separatorColor: Asset.Colors.snow.color))
                .environment(\.defaultMinListRowHeight, 12)
                .scrollDismissesKeyboard()

                TextButtonView(title: L10n.ok.uppercased(), style: .primary, size: .large, onPressed: {
                    viewModel.didClose.send()
                })
                .frame(height: TextButton.Size.large.height)
                .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle(L10n.countryCode)
        .navigationBarItems(
            trailing:
                Button(L10n.done, action: viewModel.didClose.send)
                .foregroundColor(Color(Asset.Colors.night.color))
        )
        .onAppear {
            viewModel.isSearchFieldFocused = true
        }
        .onDisappear {
            viewModel.isSearchFieldFocused = false
        }
    }
}
