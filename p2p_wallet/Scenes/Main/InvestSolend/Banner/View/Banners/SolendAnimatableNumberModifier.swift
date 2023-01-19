//
//  SimpleAnimatableNumberModifier.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import SwiftUI

struct SolendAnimatableNumberView: View {
    let number: Double
    
    var body: some View {
        Rectangle()
            .modifier(SolendAnimatableNumberModifier(number: number))
    }
}

struct SolendAnimatableNumberModifier: AnimatableModifier {
    var number: Double

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    func body(content: Content) -> some View {
        Text("\(Defaults.fiat.symbol) \(number.fixedDecimal(7, minDecimal: 7))")
            .font(uiFont: .font(of: .title1, weight: .bold))
    }
}

struct SolendAnimatableNumberModifier_Previews: PreviewProvider {
    private struct Mock: View {
        @State var value: Double
        
        var body: some View {
            VStack {
                SolendAnimatableNumberView(number: value)
                Button {
                    withAnimation(Animation.easeInOut(duration: 1)) {
                        value = value + 0.0012
                    }
                } label: {
                    Text("Increase")
                }
            }
        }
    }
    
    static var previews: some View {
        Mock(value: 50.123412)
    }
}
