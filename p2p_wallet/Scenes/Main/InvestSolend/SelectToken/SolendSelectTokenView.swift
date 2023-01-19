//
//  SolendSelectTokenView.swift
//  p2p_wallet
//
//  Created by Ivan on 04.10.2022.
//

import Combine
import Foundation
import SwiftUI

protocol SolendSelectTokenView {
    var close: AnyPublisher<Void, Never> { get }
    var symbol: AnyPublisher<String, Never> { get }
    var viewHeight: CGFloat { get }
}
