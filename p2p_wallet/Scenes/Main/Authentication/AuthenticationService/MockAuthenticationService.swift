import Foundation

 final class MockAuthenticationService: AuthenticationService {
     func shouldAuthenticateUser() -> Bool {
         Bool.random()
     }
 }
