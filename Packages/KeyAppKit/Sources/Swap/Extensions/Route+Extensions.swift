import Foundation
import Jupiter

extension Route {
    public var id: String {
        marketInfos.map(\.id).joined()
    }
    
    public func getMints() -> [String] {
        // get marketInfos
        guard !marketInfos.isEmpty
        else {
            return []
        }
        // transform route to mints
        var mints = [String]()
        for (index, info) in marketInfos.enumerated() {
            if index == 0 { mints.append(info.inputMint) }
            mints.append(info.outputMint)
        }
        return mints
        
    }
}
