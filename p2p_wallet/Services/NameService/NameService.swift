//
//  NameService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 06/10/2021.
//

import Foundation
import RxSwift

protocol NameServiceType {
    var captchaAPI1Url: String { get }

    func getName(_ owner: String) -> Single<String?>
    func getOwnerAddress(_ name: String) -> Single<String?>
    func getOwners(_ name: String) -> Single<[NameService.Owner]>
    func post(name: String, params: NameService.PostParams) -> Single<NameService.PostResponse>
}

extension NameServiceType {
    func isNameAvailable(_ name: String) -> Single<Bool> {
        getOwnerAddress(name).map { $0 == nil }
    }
}

class NameService: NameServiceType {
    private let endpoint = "https://\(String.secretConfig("FEE_RELAYER_ENDPOINT")!)/name_register"
    private let cache: NameServiceCacheType

    var captchaAPI1Url: String { endpoint + "/auth/gt/register" }

    init(cache: NameServiceCacheType) {
        self.cache = cache
    }

    func getName(_ owner: String) -> Single<String?> {
        if let result = cache.getName(for: owner) {
            return .just(result.name)
        }
        return getNames(owner)
            .map { $0.last(where: { $0.name != nil })?.name }
            .do(onSuccess: { [weak self] name in
                self?.cache.save(name, for: owner)
            })
    }

    func getOwners(_ name: String) -> Single<[Owner]> {
        catchNotFound(
            observable: request(url: endpoint + "/resolve/\(name)"),
            defaultValue: []
        )
            .do(onSuccess: { [weak self] result in
                for record in result {
                    if let name = record.name {
                        self?.cache.save(name, for: record.owner)
                    }
                }
            })
    }

    func getOwnerAddress(_ name: String) -> Single<String?> {
        let getAddress = getOwner(name)
            .map { $0?.owner }

        return catchNotFound(
            observable: getAddress,
            defaultValue: nil
        )
    }

    func post(name: String, params: PostParams) -> Single<PostResponse> {
        let urlString = "\(endpoint)/\(name)"
        let url = URL(string: urlString)!

        return Single.async {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(params)
            let (data, _) = try await URLSession.shared.data(from: urlRequest)
            return try JSONDecoder().decode(PostResponse.self, from: data)
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
                if let error = error as? NameService.Error,
                   error == .notFound
                {
                    return .just(defaultValue)
                }

                throw error
            }
    }

    private func request<T: Decodable>(url: String) -> Single<T> {
        Single.async {
            guard let url = URL(string: url) else {
                throw NameService.Error.invalidURL
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else {
                throw NameService.Error.invalidResponseCode
            }
            switch response.statusCode {
            case 200 ... 299:
                return try JSONDecoder().decode(T.self, from: data)
            default:
                throw NameService.Error.invalidStatusCode(response.statusCode)
            }
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

    enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidResponseCode
        case invalidStatusCode(Int)
        case unknown

        static var notFound: Self {
            .invalidStatusCode(404)
        }
    }
}
