import Foundation

 final class MockAuthenticationService: AuthenticationService {
     private var int = 0
     func shouldAuthenticateUser() -> Bool {
         int += 1
         return int % 2 == 0
     }
 }
