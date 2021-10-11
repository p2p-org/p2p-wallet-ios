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
    func getOwner(_ name: String) -> Single<String?>
    func post(name: String, params: NameService.PostParams) -> Single<NameService.PostResponse>
}

extension NameServiceType {
    func isNameAvailable(_ name: String) -> Single<Bool> {
        getOwner(name).map {$0 == nil}
    }
}

struct NameService: NameServiceType {
    private let endpoint = "https://\(Bundle.main.infoDictionary!["FEE_RELAYER_ENDPOINT"] as! String)/name_register"
    
    var captchaAPI1Url: String {endpoint + "/auth/gt/register"}
    
    func getName(_ owner: String) -> Single<String?> {
        (request(url: endpoint + "/lookup/\(owner)") as Single<[Name]>)
            .map {$0.last(where: {$0.name != nil})?.name}
    }
    
    func getOwner(_ name: String) -> Single<String?> {
        (request(url: endpoint + "/\(name)") as Single<Owner?>)
            .map {$0?.owner}
            .catch { error in
                if let error = error as? AFError {
                    switch error {
                    case .responseValidationFailed(let reason):
                        switch reason {
                        case .unacceptableStatusCode(let code):
                            if code == 404 {
                                return .just(nil)
                            }
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
                throw error
            }
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
                .map {_, data in
                    try JSONDecoder().decode(PostResponse.self, from: data)
                }
        } catch {
            return .error(error)
        }
    }
    
    private func request<T: Decodable>(url: String) -> Single<T> {
        RxAlamofire.request(.get, url)
            .validate(statusCode: 200 ..< 300)
            .responseData()
            .take(1)
            .asSingle()
            .map {_, data in
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
//        let data: [JSONAny]
        
        enum CodingKeys: String, CodingKey {
            case parentName = "parent_name"
            case owner
            case ownerClass = "class"
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
