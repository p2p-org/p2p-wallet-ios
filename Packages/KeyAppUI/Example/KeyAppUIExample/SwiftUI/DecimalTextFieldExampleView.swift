//
//  SwiftUIView.swift
//  KeyAppUIExample
//
//  Created by Chung Tran on 12/12/2022.
//

import SwiftUI
import KeyAppUI

struct DecimalTextFieldExampleView: View {
    @State var value: Double?
    @State var isFirstResponder: Bool = false
    @State var textColor: UIColor = Asset.Colors.night.color

    private var colorVariants = [Asset.Colors.night.color, Asset.Colors.rose.color, Asset.Colors.rain.color, Asset.Colors.lime.color]

    private let decimalSeparator = Bool.random() ? ".": ","
    private let maximumFractionDigits = Int.random(in: 2..<6)
    private let maxVariable = [Double]([100, 1000, 10000000]).randomElement()!
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("DecimalTextField, decimalSeparator: \"\(decimalSeparator)\", maximumFractionDigits: \(maximumFractionDigits), max: \(maxVariable)")
            HStack {
                DecimalTextField(
                    value: $value,
                    isFirstResponder: $isFirstResponder,
                    textColor: $textColor
                ) { textField in
                    textField.decimalSeparator = decimalSeparator
                    textField.maximumFractionDigits = maximumFractionDigits
                    textField.max = maxVariable
                    textField.placeholder = "0"
                }
                .frame(maxHeight: 40)
                Text("Result: \(value ?? 0)")
            }
            Button("Switch color") {
                textColor = colorVariants.randomElement() ?? .black
            }
            Spacer()
        }.padding()
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DecimalTextFieldExampleView()
    }
}
