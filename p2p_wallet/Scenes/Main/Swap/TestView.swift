//
//  TestView.swift
//  p2p_wallet
//
//  Created by Ivan on 02.02.2023.
//

import SwiftUI
import Jupiter
import Resolver
import SolanaSwift

struct TestView: View {
    private let jupiterClient = JupiterRestClientAPI(version: .v4)
    @Injected private var walletsRepository: WalletsRepository
    
    @State var tokens = [Jupiter.Token]()
    
    @State var inputToken: Jupiter.Token!
    @State var outputToken: Jupiter.Token!
    
    @State var pendingQuote = false
    
    @State var serializedTransactionBase64: String?
    @State var transactionId: String?
    
    @State var error: String?
    
    var body: some View {
        VStack(spacing: 24) {
            if tokens.isEmpty {
                ActivityIndicator(isAnimating: true)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Picker("Input Token", selection: $inputToken) {
                                ForEach(tokens, id: \.self) {
                                    Text("\($0.name) (\($0.symbol))")
                                }
                            }
                            Spacer()
                            Picker("Output Token", selection: $outputToken) {
                                ForEach(tokens, id: \.self) {
                                    Text("\($0.name) (\($0.symbol))")
                                }
                            }
                        }
                        HStack {
                            Text("Serialized Transaction Base64")
                            Spacer()
                            if pendingQuote {
                                ActivityIndicator(isAnimating: true)
                            } else {
                                Text(serializedTransactionBase64 ?? "")
                            }
                        }
                        HStack {
                            Text("Transaction id after send")
                            Spacer()
                            if pendingQuote {
                                ActivityIndicator(isAnimating: true)
                            } else {
                                Text(transactionId ?? "")
                            }
                        }
                        if let error = error {
                            HStack {
                                Text("Error")
                                Spacer()
                                Text(error)
                            }
                        }
                    }
                }
                Button("Swap") {
                    test()
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                if tokens.isEmpty {
//                    tokens = try await jupiterClient.getTokens()
                    inputToken = tokens[0]
                    outputToken = tokens[10]
                }
            }
        }
    }
    
    func test() {
        guard let inputToken = inputToken, let outputToken = outputToken else { return }
        
        let inputTokenAddress = inputToken.address
        let outputTokenAddress = outputToken.address
        
        serializedTransactionBase64 = nil
        transactionId = nil
        error = nil
        
        Task {
            pendingQuote = true
            
            let routes = try! await jupiterClient.quote(inputMint: inputTokenAddress, outputMint: outputTokenAddress, amount: "200", swapMode: nil, slippageBps: nil, feeBps: nil, onlyDirectRoutes: nil, userPublicKey: nil, enforceSingleTx: nil).data
            
            let userWalletManager: UserWalletManager = Resolver.resolve()
            let account = userWalletManager.wallet!.account
            let pubKey = account.publicKey.base58EncodedString
            let solanaAPIClient: SolanaAPIClient = Resolver.resolve()
            
            do {
                var versionedTransaction = try! await jupiterClient.swap(route: routes[0], userPublicKey: pubKey, wrapUnwrapSol: true, feeAccount: nil, asLegacyTransaction: nil, computeUnitPriceMicroLamports: nil, destinationWallet: nil)
                
                let blockHash = try await solanaAPIClient.getRecentBlockhash()
                versionedTransaction?.setRecentBlockHash(blockHash)
                try versionedTransaction?.sign(signers: [account])
                
                let serializedTransaction = try versionedTransaction?.serialize().base64EncodedString()
                serializedTransactionBase64 = serializedTransaction
                
                let transactionId = try await solanaAPIClient.sendTransaction(
                    transaction: serializedTransaction ?? "",
                    configs: .init(encoding: "base64")!
                )
                self.transactionId = transactionId
            } catch {
                self.error = error.localizedDescription
            }
            
            pendingQuote = false
        }
    }
}

extension Jupiter.Token: Hashable {
    public static func == (lhs: Jupiter.Token, rhs: Jupiter.Token) -> Bool {
        lhs.address == rhs.address && lhs.symbol == rhs.symbol && lhs.name == rhs.name
    }
    
    public var id: String {
        symbol + name + address
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(chainId)
        hasher.combine(decimals)
        hasher.combine(name)
        hasher.combine(symbol)
        hasher.combine(logoURI)
        hasher.combine(extensions?.coingeckoId)
        hasher.combine(tags)
    }
}
