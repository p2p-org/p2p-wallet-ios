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
                    self.updatePair(pair, value: value)
                })
                .disposed(by: disposeBag)
        }
    }
    
    func fetch(pair: Pair) -> Single<Double> {
        request(.get, "https://serum-api.bonfida.com/candles/\(pair.from)\(pair.to)?limit=1&resolution=60")
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseData()
            .take(1)
            .asSingle()
            .map {try JSONDecoder().decode(Response.self, from: $0.1)}
            .map {
                $0.data?.first?.close ?? 0
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
    }
}
