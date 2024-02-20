import SwiftUI

struct FlagDebugMenuView: View {
    var body: some View {
        List {
            DebugText(title: "ETH Address", value: "\(available(.ethAddressEnabled))")
            DebugText(title: "Invest Solend", value: "\(available(.investSolendFeature))")
            DebugText(title: "Mocked API Gateway", value: "\(available(.mockedApiGateway))")
            DebugText(title: "Mocked TKey Facade", value: "\(available(.mockedTKeyFacade))")
            DebugText(title: "Onboarding Username", value: "\(available(.onboardingUsernameEnabled))")
            DebugText(title: "Onboarding Username Button Skip", value: "\(available(.onboardingUsernameButtonSkipEnabled))")
            DebugText(title: "PnL", value: "\(available(.pnlEnabled))")
            DebugText(title: "Referral Program", value: "\(available(.referralProgramEnabled))")
            DebugText(title: "Send Via Link", value: "\(available(.sendViaLinkEnabled))")
            DebugText(title: "Simulated Social Error", value: "\(available(.simulatedSocialError))")
            DebugText(title: "Solana ETH Address", value: "\(available(.solanaEthAddressEnabled))")
            DebugText(title: "Solana Negative Status", value: "\(available(.solanaNegativeStatus))")
            DebugText(title: "Solend Disable Placeholder", value: "\(available(.solendDisablePlaceholder))")
            DebugText(title: "Swap Transaction Simulation", value: "\(available(.swapTransactionSimulationEnabled))")
            DebugText(title: "Sell Scenario", value: "\(available(.sellScenarioEnabled))")
        }
        .navigationTitle("Flags")
    }
}
