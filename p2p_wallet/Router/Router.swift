import Foundation

class BaseRouter {
    enum ParamType: String {
        case int
        case float
        case string
    }
    
    private func getClassesImplementingProtocol(prot: Protocol) -> [AnyClass] {
        let classes = objc_getClassList()
        var ret = [AnyClass]()
        
        for cls in classes {
            if class_conformsToProtocol(cls, prot) {
                ret.append(cls)
            }
        }
        return ret
    }
    
    private func objc_getClassList() -> [AnyClass] {
        let expectedClassCount = ObjectiveC.objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        let actualClassCount:Int32 = ObjectiveC.objc_getClassList(autoreleasingAllClasses, Int32(expectedClassCount))
        
        var classes = [AnyClass]()
        for idx in 0 ..< actualClassCount {
            if let currentClass: AnyClass = allClasses[Int(idx)] {
                classes.append(currentClass)
            }
        }
        
        allClasses.deallocate()
        return classes
    }
    
    // MARK: -
    
    private func matches(pattern: String, origin: String) -> (Bool, [String: Any], [String]) {
        let components1 = pattern.components(separatedBy: "/").filter { (str) -> Bool in
            return str != ""
        }
        
        let components2 = origin.components(separatedBy: "/").filter { (str) -> Bool in
            return str != ""
        }
        
        let characterSet = CharacterSet.init(charactersIn: "<>")
        
        //длины путей должнsы быть одинаковыми
        guard components1.count == components2.count else {
            return (false, [:], [])
        }
        
        var resDict = [String : Any]()
        var resPathDict = [String]()
        
        for (c1, c2) in zip(components1, components2) {
            if c2.hasPrefix("<") {
                let val = c2.trimmingCharacters(in: characterSet)
                let keyValue = val.components(separatedBy: ":")
                let (key, value) = (keyValue[0], keyValue[1])
                
                var tempValue: Any?
                
                let paramType = ParamType(rawValue: key)
                guard paramType != nil else {
                    return (false, [:], [])
                }
                
                switch paramType! {
                case .int:
                    tempValue = Int(c1)
                    break
                    
                case .float:
                    tempValue = Float(c1)
                    break
                    
                case .string:
                    tempValue = (try? String(c1)) ?? ""
                    break
                }
                
                if tempValue != nil {
                    resDict[value] = tempValue
                } else {
                    return (false, [:], [])
                }
            } else {
                if c2 != c1 {
                    return (false, [:], [])
                } else {
                    resPathDict.append(c2)
                }
            }
        }
        return (true, resDict, resPathDict)
    }
}

@objc protocol URLInitializable: class {
    static var pattern: String { get }
    static func viewController(params: [String: Any]) -> BaseViewController?
}
