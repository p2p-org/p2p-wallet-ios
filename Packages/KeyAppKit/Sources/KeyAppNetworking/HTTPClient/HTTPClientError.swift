//
//  ErrorModel.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

public enum HTTPClientError: Error {
    case invalidURL(String)
    case invalidResponse(HTTPURLResponse?, Data)
}
