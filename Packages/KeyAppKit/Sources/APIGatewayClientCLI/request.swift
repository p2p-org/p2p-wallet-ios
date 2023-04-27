// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import ArgumentParser
import Foundation
import Onboarding
import TweetNacl

@main
enum App {
    static func main() async {
        await APIGatewayClientCommand.main()
    }
}

struct APIGatewayClientCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool for API Gateway",
        subcommands: [Request.self, GenerateSolanaPrivateKey.self]
    )
}

enum RequestType: String, ExpressibleByArgument {
    case registerWallet
}

struct GenerateSolanaPrivateKey: AsyncParsableCommand {
    func run() async throws {
        let keypair = try NaclSign.KeyPair.keyPair()
        try print(Base58.encode(keypair.secretKey))
    }
}

struct Request: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Communication with API Gateway")

    @Argument(help: "Type of request")
    private var type: RequestType

    @Argument()
    private var phone: String

    @Argument()
    private var solanaPubkey: String

    @Argument()
    private var ethId: String

    @Flag(name: .long, help: "Return as cURL")
    private var curl: Int

    @Option(name: .long, help: "The endpoint (default: \"https://web3-auth.keyapp.org\"")
    var endPoint: String?

    // @Flag(name: .long, help: "Show extra logging for debugging purposes")
    // private var verbose: Bool

    func run() async throws {
        switch type {
        case .registerWallet:
            let endpoint = endPoint ?? "https://web3-auth.keyapp.org"
            let networkManager: NetworkManager
            if curl == 1 {
                networkManager = URLSessionInterceptor { request in
                    print(request.cURL(pretty: false))
                }
            } else {
                networkManager = URLSession.shared
            }

            do {
                let client = APIGatewayClientImpl(endpoint: endpoint, networkManager: networkManager)
                try await client.registerWallet(
                    solanaPrivateKey: solanaPubkey,
                    ethAddress: ethId,
                    phone: phone,
                    channel: .sms,
                    timestampDevice: Date()
                )
            } catch {}
        }
    }
}
