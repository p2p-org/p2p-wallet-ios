import Foundation

 final class MockAuthenticationService: AuthenticationService {
     private var int = 1
     func shouldAuthenticateUser() -> Bool {
         int += 1
         return int % 2 == 0
     }
 }
