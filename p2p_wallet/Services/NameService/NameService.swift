//
//  NameService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/10/2021.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire

protocol NameServiceType {
    var captchaAPI1Url: String {get}
    
    func getName(_ owner: String) -> Single<String?>
    func getOwnerAddress(_ name: String) -> Single<String?>
    func getOwners(_ name: String) -> Single<[NameService.Owner]>
    func post(name: String, params: NameService.PostParams) -> Single<NameService.PostResponse>
}

extension NameServiceType {
    func isNameAvailable(_ name: String) -> Single<Bool> {
        getOwnerAddress(name).map {$0 == nil}
    }
}

class NameService: NameServiceType {
    private let endpoint = "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)/name_register"
    private let cache: NameServiceCacheType
    
    var captchaAPI1Url: String {endpoint + "/auth/gt/register"}
    
    init(cache: NameServiceCacheType) {
        self.cache = cache
    }
    
    func getName(_ owner: String) -> Single<String?> {
        if let result = cache.getName(for: owner) {
            return .just(result.name)
        }
        return getNames(owner)
            .map {$0.last(where: {$0.name != nil})?.name}
            .do(onSuccess: { [weak self] name in
                self?.cache.save(name, for: owner)
            })
    }

    func getOwners(_ name: String) -> Single<[Owner]> {
        catchNotFound(
            observable: request(url: endpoint + "/resolve/\(name)"),
            defaultValue: []
        )
            .do(onSuccess: {[weak self] result in
                for record in result {
                    if let name = record.name {
                        self?.cache.save(name, for: record.owner)
                    }
                }
            })
    }

    func getOwnerAddress(_ name: String) -> Single<String?> {
        let getAddress = getOwner(name)
            .map {$0?.owner}

        return catchNotFound(
            observable: getAddress,
            defaultValue: nil
        )
    }
    
    func post(name: String, params: PostParams) -> Single<PostResponse> {
        let urlString = "\(endpoint)/\(name)"
        guard let url = URL(string: urlString) else {
            return .error(Alamofire.AFError.invalidURL(url: urlString))
        }
        do {
            var urlRequest = try URLRequest(url: url, method: .post, headers: [.contentType("application/json")])
            urlRequest.httpBody = try JSONEncoder().encode(params)
            return RxAlamofire.request(urlRequest)
                .validate(statusCode: 200 ..< 300)
                .responseData()
                .take(1)
                .asSingle()
                .debug()
                .map { $1 }
                .map { data in
                    try JSONDecoder().decode(PostResponse.self, from: data)
                }
        } catch {
            return .error(error)
        }
    }

    private func getOwner(_ name: String) -> Single<Owner?> {
        request(url: endpoint + "/\(name)")
    }

    private func getNames(_ owner: String) -> Single<[Name]> {
        request(url: endpoint + "/lookup/\(owner)")
    }

    private func catchNotFound<T>(observable: Single<T>, defaultValue: T) -> Single<T> {
        observable
            .catch { error in
                guard case AFError.responseValidationFailed(.unacceptableStatusCode(404)) = error else {
                    throw error
                }

                return .just(defaultValue)
            }
    }
    
    private func request<T: Decodable>(url: String) -> Single<T> {
        RxAlamofire.request(.get, url)
            .validate(statusCode: 200 ..< 300)
            .responseData()
            .take(1)
            .asSingle()
            .map { $1 }
            .map { data in
                try JSONDecoder().decode(T.self, from: data)
            }
    }
}

extension NameService {
    struct Name: Decodable {
        let address: String?
        let name: String?
        let parent: String?
    }

    struct Owner: Decodable {
        let parentName, owner, ownerClass: String
        let name: String?
//        let data: [JSONAny]
        
        enum CodingKeys: String, CodingKey {
            case parentName = "parent_name"
            case owner
            case ownerClass = "class"
            case name
//            case data
        }
    }
    
    struct PostParams: Encodable {
        let owner: String
        let credentials: Credentials
        
        struct Credentials: Encodable {
            let geetest_validate: String
            let geetest_seccode: String
            let geetest_challenge: String
        }
    }
    
    struct PostResponse: Decodable {
        let signature: String
    }
}
