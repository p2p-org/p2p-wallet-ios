//import Foundation
//
//public struct ReauthenticationWithoutDeviceShareProvider {
//    let apiGateway: APIGatewayClient
//    let facade: TKeyFacade
//}
//
//public enum ReauthenticationWithoutDeviceShareEvent: Codable, Equatable {
//    case enterOTP
//    case resendOTP
//    case loginBySocialProvider
//}
//
//public enum ReauthenticationWithoutDeviceShareState: Codable, State, Equatable {
//    public typealias Event = ReauthenticationWithoutDeviceShareEvent
//    public typealias Provider = ReauthenticationWithoutDeviceShareProvider
//
//    public static var initialState: Self = .otpInput
//
//    case otpInput
//    case socialLogin
//
//    public func accept(
//        currentState: ReauthenticationWithoutDeviceShareState,
//        event: ReauthenticationWithoutDeviceShareEvent,
//        provider: ReauthenticationWithoutDeviceShareProvider
//    ) async throws -> Self {
//        switch currentState {
//        case .otpInput:
//            return handleActionForOtpInput(
//                event: event,
//                provider: provider
//            )
//        case .socialLogin:
//            return handleActionForSocialLogin(
//                event: event,
//                provider: provider
//            )
//        }
//    }
//
//    func handleActionForOtpInput(
//        event: ReauthenticationWithoutDeviceShareEvent,
//        provider _: ReauthenticationWithoutDeviceShareProvider
//    ) -> Self {
//        switch event {
//        case .enterOTP:
//            
//        }
//    }
//
//    func handleActionForSocialLogin(
//        event _: ReauthenticationWithoutDeviceShareEvent,
//        provider _: ReauthenticationWithoutDeviceShareProvider
//    ) -> Self {}
//}
