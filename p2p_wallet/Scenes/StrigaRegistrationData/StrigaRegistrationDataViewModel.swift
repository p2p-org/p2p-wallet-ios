import Combine
import BankTransfer

final class StrigaRegistrationDataViewModel: BaseViewModel, ObservableObject {
    
    // Fields
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var firstName: String = ""
    @Published var surname: String = ""
    @Published var dateOfBirth: String = ""
    @Published var countryOfBirth: String = ""
    
    // Other views
    @Published var actionTitle: String = L10n.next
    @Published var isDataValid = true
    let next = PassthroughSubject<Void, Never>()
}
