//
//  File.swift
//  
//
//  Created by Giang Long Tran on 20.04.2023.
//

import Foundation

public protocol DataAggregator<Input, Output> {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
