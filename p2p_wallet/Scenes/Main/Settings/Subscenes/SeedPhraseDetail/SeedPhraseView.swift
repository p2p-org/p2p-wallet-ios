//
//  SeedPhraseView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 01.09.2022.
//

import CarPlay
import KeyAppUI
import SwiftUI

struct SeedPhraseView: View {
    let seedPhrase: [String]

    @State var hidden: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                HStack {
                    Text(L10n.seedPhrase)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))

                    Spacer()

                    TextButtonView(
                        title: !hidden ? L10n.hide : L10n.show,
                        style: .second,
                        size: .small,
                        trailing: !hidden ? .eyeHiddenTokensHide : .eyeHiddenTokens
                    ) { hidden = !hidden }
                        .frame(maxWidth: 100, maxHeight: TextButton.Size.small.height)
                }

                ScrollView {
                    Grid(columns: 3, list: seedPhrase) { word in
                        Text(word)
                            .apply(style: .text4)
                    }
                    .padding(4)
                    .blur(radius: hidden ? 4 : 0)
                }.frame(maxHeight: .infinity)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(Asset.Colors.rain.color), lineWidth: 1)
        )
    }

    var seedPhraseOverlay: some View {
        Color.white
            .blur(radius: 8)
    }
}

/// A grid view
private struct Grid<Content: View, T: Hashable>: View {
    private let columns: Int
    private var list: [[T]] = []
    private let content: (T) -> Content

    private mutating func setupList(_ list: [T]) {
        var column = 0
        var columnIndex = 0

        for object in list {
            if columnIndex < columns {
                if columnIndex == 0 {
                    self.list.insert([object], at: column)
                    columnIndex += 1
                } else {
                    self.list[column].append(object)
                    columnIndex += 1
                }
            } else {
                column += 1
                self.list.insert([object], at: column)
                columnIndex = 1
            }
        }
    }

    init(columns: Int, list: [T], @ViewBuilder content: @escaping (T) -> Content) {
        self.columns = columns
        self.content = content
        setupList(list)
    }

    var body: some View {
        VStack {
            ForEach(0 ..< self.list.count, id: \.self) { i in
                HStack {
                    ForEach(0 ..< 3, id: \.self) { j in
                        cellElement(i, j)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    func cellElement(_ i: Int, _ j: Int) -> AnyView {
        if j < list[i].count {
            let child = HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(i * 3 + (j + 1))")
                    .apply(style: .text4)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                content(self.list[i][j])
                Spacer()
            }

            return AnyView(child)
        } else {
            let child = HStack {
                Text("")
                Spacer()
            }

            return AnyView(child)
        }
    }
}

struct SeedPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        SeedPhraseView(seedPhrase: [
            "world",
            "buy",
            "car",
            "house",
            "phone",
            "world",
            "buy",
            "car",
            "house",
            "phone",
            "world",
            "buy",
            "car",
            "house",
            "phone",
        ])
    }
}
