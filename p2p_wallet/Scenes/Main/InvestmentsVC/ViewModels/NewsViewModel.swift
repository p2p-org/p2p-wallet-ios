//
//  NewsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import BECollectionView
import Foundation
import RxSwift

class NewsViewModel: BEListViewModel<News> {
    override func createRequest() -> Single<[News]> {
        super.createRequest()
            .map { _ in
                [
                    News(id: "1", title: "How it works", subtitle: "The most important info you should know before investing", imageUrl: nil),
                    News(id: "2", title: "How it works2", subtitle: "The most important info you should know before investing2", imageUrl: nil),
                    News(id: "3", title: "How it works2", subtitle: "The most important info you should know before investing2", imageUrl: nil),
                ]
            }
    }
}
