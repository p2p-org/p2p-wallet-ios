//
//  ViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 17.04.2022.
//

import Foundation

public protocol ViewModelWithIO {
    associatedtype Input
    associatedtype Output
    var input: Input { get }
    var output: Output { get }
}

public extension ViewModelWithIO {
    var io: (Input, Output) {
        return (input, output)
    }
}

public protocol ViewModelIO {
    associatedtype View
    associatedtype Coord
    var view: View { get }
    var coord: Coord { get }
}

public protocol ViewModel: ViewModelWithIO where Input: ViewModelIO, Output: ViewModelIO {}

public extension ViewModel {
    var viewIO: (Input.View, Output.View) {
        return (input.view, output.view)
    }

    var coordIO: (Input.Coord, Output.Coord) {
        return (input.coord, output.coord)
    }
}
