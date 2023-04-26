@testable import KeyAppBusiness
import Web3
import Web3ContractABI
import XCTest

final class EthereumTests: XCTestCase {
    let web3 = Web3(rpcURL: "https://eth-mainnet.g.alchemy.com/v2/a3NxxBPY4WUcsXnivRq-ikYKXFB67oXm")
    
    func testGetBalance() throws {
        let expectation = expectation(description: "Get balance callback")

        web3.eth.getBalance(address: try .init(hex: "0x0583B332697C1406E8fa82deBF224B285Dc25632", eip55: true), block: .latest) { response in
            print(response)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGetERC20Tokens() throws {
        let expectation = expectation(description: "Get balance callback")
        
        let contractAddress = try EthereumAddress(hex: "0xF3e014fE81267870624132ef3A646B8E83853a96", eip55: true)
        let contract = web3.eth.Contract(type: GenericERC20Contract.self, address: contractAddress)
        
        contract.balanceOf(address: try EthereumAddress(hex: "0x96b1BE95ca5ec06d9bd6926e1c5302E1265049C0", eip55: true)).call { response, error in
            print(response, error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
    }
    
    func testGetAllToken() throws {
        let expectation = expectation(description: "Get logs callback")
        
        web3.eth.getLogs(
            addresses: [try .init(hex: "0x96b1BE95ca5ec06d9bd6926e1c5302E1265049C0", eip55: true)],
            topics: nil,
            fromBlock: .earliest,
            toBlock: .latest
        ) { resp in
            print(resp)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100)
    }
    
    func testGetAllBalances() throws {
        let expectation = expectation(description: "Get logs callback")
        
        web3.eth.getTokenBalances(address: try .init(hex: "0x0583B332697C1406E8fa82deBF224B285Dc25632", eip55: true)) { resp in
            print(resp)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100)
    }
}
