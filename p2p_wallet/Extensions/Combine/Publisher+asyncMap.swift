//
//  Publisher+asyncMap.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/06/2022.
//

import Combine
import Foundation

// https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline/

extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }

    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }

//    func asyncMap<T>(
//        _ transform: @escaping (Output) async throws -> T
//    ) -> Publishers.FlatMap<Future<T, Error>,
//                            Publishers.SetFailureType<Self, Error>>
//    {
//        if #available(iOS 14.0, *) {
//            flatMap { value in
//                Future { promise in
//                    Task {
//                        do {
//                            let output = try await transform(value)
//                            promise(.success(output))
//                        } catch {
//                            promise(.failure(error))
//                        }
//                    }
//                }
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//    }
}
