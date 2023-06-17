import Foundation
import Combine

final class AuthenticationPincodeViewModel: BaseViewModel, ObservableObject {

    // MARK: - Properties

    private var pincodeDidVerifySubject = PassthroughSubject<Void, Never>()
    @Published var pincode: String = ""

    // MARK: - Computed properties

    var pincodeDidVerify: AnyPublisher<Void, Never> {
        pincodeDidVerifySubject.eraseToAnyPublisher()
    }
    
    // MARK: - Methods

    func verify() {
        if pincode == "123456" {
            pincodeDidVerifySubject.send(())
        }
    }
}
