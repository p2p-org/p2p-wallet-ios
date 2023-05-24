import SwiftUI
import KeyAppUI

fileprivate typealias TextField = StrigaRegistrationTextField
fileprivate typealias InfoView = StrigaRegistrationInformerView

struct StrigaRegistrationDataView: View {
    @ObservedObject private var viewModel: StrigaRegistrationDataViewModel

    init(viewModel: StrigaRegistrationDataViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            List {
                InfoView()
                    .listRowBackground(Color(Asset.Colors.smoke.color))
                    .listRowInsets(EdgeInsets.infoInset)

                Section(header: section(header: L10n.contacts)) {
                    TextField(title: L10n.email, placeholder: L10n.enter, text: $viewModel.email)
                    TextField(title: L10n.phoneNumber, placeholder: L10n.enter, text: $viewModel.phoneNumber)
                }
                .listRowBackground(Color(Asset.Colors.smoke.color))
                .listRowInsets(EdgeInsets.rowInset)
                .modifier(ListBackgroundModifier(separatorColor: .clear))

                Section(header: section(header: L10n.credentials)) {
                    TextField(title: L10n.firstName, placeholder: L10n.enter, text: $viewModel.firstName, isInvalid: true)
                    TextField(title: L10n.surname, placeholder: L10n.enter, text: $viewModel.surname)
                }
                .listRowBackground(Color(asset: Asset.Colors.smoke))
                .listRowInsets(EdgeInsets.rowInset)
                .modifier(ListBackgroundModifier(separatorColor: .clear))

                Section(header: section(header: L10n.dateOfBirth)) {
                    TextField(title: L10n.dateOfBirth, placeholder: L10n.Dd.Mm.yyyy, text: $viewModel.dateOfBirth)
                    TextField(title: L10n.countryOfBirth, placeholder: L10n.selectFromList, text: $viewModel.countryOfBirth, isDetailed: true)
                }
                .listRowBackground(Color(Asset.Colors.smoke.color))
                .listRowInsets(EdgeInsets.rowInset)
                .modifier(ListBackgroundModifier(separatorColor: .clear))
            }
            .listStyle(.insetGrouped)
            .modifier(ListBackgroundModifier(separatorColor: .clear))
            .background(Color(asset: Asset.Colors.smoke))

            TextButtonView(title: viewModel.actionTitle.uppercaseFirst, style: .primaryWhite, size: .large, trailing: .arrowForward, onPressed: viewModel.next.send)
                .frame(height: TextButton.Size.large.height)
                .padding(.all, 16)
                .disabled(!viewModel.isDataValid)
        }.background(
            Color(asset: Asset.Colors.smoke).ignoresSafeArea()
        )
    }
}

private extension StrigaRegistrationDataView {
    func section(header: String) -> some View {
        Text(header).foregroundColor(Color(asset: Asset.Colors.night)).padding(.leading, 8)
    }
}

private extension EdgeInsets {
    static let rowInset = EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
    static let infoInset = EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
}

struct StrigaRegistrationDataView_Previews: PreviewProvider {
    static var previews: some View {
        StrigaRegistrationDataView(
            viewModel: StrigaRegistrationDataViewModel()
        )
    }
}
