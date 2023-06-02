//
//  MockHTTPClient.swift
//  
//
//  Created by Ivan on 24.05.2023.
//

import Foundation

final class MockHTTPClient: IHTTPClient {
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - IHTTPClient
    
    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: (endpoint: (any HTTPEndpoint)?, Void)?
    var invokedRequestParametersList = [any HTTPEndpoint]()
    var stubbedRequestResult: Any?
    
    func request<T: Decodable>(endpoint: any HTTPEndpoint, responseModel: T.Type) async throws -> T {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = (endpoint, ())
        invokedRequestParametersList.append(endpoint)
        
        if let result = stubbedRequestResult {
            guard let model = result as? T else {
                throw NSError(domain: "", code: 0)
            }
            return model
        }
        
        throw NSError(domain: "", code: 0)
    }
}
