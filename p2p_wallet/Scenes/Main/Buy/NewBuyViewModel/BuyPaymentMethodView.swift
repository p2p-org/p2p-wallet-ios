//
//  BuyPaymentMethodViewq.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.09.2022.
//

import KeyAppUI
import SwiftUI

struct BuyPaymentMethodView: View {
    private let textLeadingPadding = 24.0
    private let cardLeadingPadding = 16.0

    let payment: BuyPaymentMethod
    let selected: Bool

    private var info: BuyPaymentMethodInfo {
        payment.info()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack(alignment: .bottom) {
                    Text(info.fee)
                        .apply(style: .title2)

                    Text("fee")
                        .apply(style: .label1)
                        .padding(.bottom, 3)
                        .padding(.leading, -4)
                    Spacer()
                }
                Spacer()

                // Selected
                if selected {
                    Image("checkmark-filled")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .padding(.trailing, 13)
                        .padding(.top, -3)
                } else {
                    Image("checkmark-empty")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .padding(.trailing, 13)
                        .padding(.top, -3)
                }
            }.padding(EdgeInsets(top: 13, leading: cardLeadingPadding, bottom: 0, trailing: 0))

            Text(info.duration)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, -9)
                .padding(.leading, cardLeadingPadding)

            HStack(alignment: .top) {
                Text(info.name)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Image(uiImage: info.icon)
                    .padding(.leading, -4)
                    .padding(.top, -1)
                Spacer()
            }.padding(EdgeInsets(top: 5, leading: cardLeadingPadding, bottom: 12, trailing: 0))
        }
        .frame(width: 145)
        .background(Color(Asset.Colors.cloud.color))
        .cornerRadius(16)
        .addBorder(selected ? Color(Asset.Colors.night.color) : Color.clear, width: 1, cornerRadius: 16)
    }
}

struct BuyPaymentMethodView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(Asset.Colors.rain.color)
            VStack {
                BuyPaymentMethodView(payment: .card, selected: false)
                BuyPaymentMethodView(payment: .bank, selected: true)
            }
        }
    }
}
