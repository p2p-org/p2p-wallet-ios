//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation
import KeyAppStateMachine

public enum NSendInputAction: Action {
    case calculate(input: NSendInput)

    case enterCalculate

    case receiveError(input: NSendInput, output: NSendOutput?, error: NSendError)
}
