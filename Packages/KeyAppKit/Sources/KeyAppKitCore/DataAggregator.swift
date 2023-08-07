import Foundation

public protocol DataAggregator<Input, Output> {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
