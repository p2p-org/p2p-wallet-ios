//
//  BonfidaPricesFetcher.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation
import RxCocoa
import RxAlamofire
import RxSwift

struct BonfidaPricesFetcher: PricesFetcher {
    struct Response: Decodable {
        let success: Bool?
        let data: [ResponseData]?
    }
    
    struct ResponseData: Decodable {
        let close: Double?
        let open: Double?
        let low: Double?
        let high: Double?
        
        // TODO:
    }
    
    var pairs = [Pair]()
    let disposeBag = DisposeBag()
    let prices = BehaviorRelay<[Price]>(value: [])
    
    func fetchAll() {
        for pair in pairs {
            fetch(pair: pair)
                .subscribe(onSuccess: { value in
                    var prices = self.prices.value
                    if let index = prices.firstIndex(where: {$0.from == pair.from && $0.to == pair.to})
                    {
                        var price = prices[index]
                        price.value = value
                        prices[index] = price
                        self.prices.accept(prices)
                    } else {
                        prices.append(Price(from: pair.from, to: pair.to, value: value))
                    }
                    self.prices.accept(prices)
                })
                .disposed(by: disposeBag)
        }
    }
    
    func fetch(pair: Pair) -> Single<Double> {
        request(.get, "https://serum-api.bonfida.com/candles/\(pair.from)\(pair.to)?limit=1&resolution=60")
            .debug()
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData()
            .take(1)
            .asSingle()
            .map {try JSONDecoder().decode(Response.self, from: $0.1)}
            .map {
                $0.data?.first?.close ?? 0
            }
    }
}
