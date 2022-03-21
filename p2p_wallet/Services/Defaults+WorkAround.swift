import Foundation
import SwiftyUserDefaults

public extension DefaultsSerializable {
    static var _defaultsArray: DefaultsArrayBridge<[T]> { DefaultsArrayBridge() }
}

extension Date: DefaultsSerializable {
    public static var _defaults: DefaultsObjectBridge<Date> { DefaultsObjectBridge() }
}

extension String: DefaultsSerializable {
    public static var _defaults: DefaultsStringBridge { DefaultsStringBridge() }
}

extension Int: DefaultsSerializable {
    public static var _defaults: DefaultsIntBridge { DefaultsIntBridge() }
}

extension Double: DefaultsSerializable {
    public static var _defaults: DefaultsDoubleBridge { DefaultsDoubleBridge() }
}

extension Bool: DefaultsSerializable {
    public static var _defaults: DefaultsBoolBridge { DefaultsBoolBridge() }
}

extension Data: DefaultsSerializable {
    public static var _defaults: DefaultsDataBridge { DefaultsDataBridge() }
}

extension URL: DefaultsSerializable {
    #if os(Linux)
        public static var _defaults: DefaultsKeyedArchiverBridge<URL> { DefaultsKeyedArchiverBridge() }
    #else
        public static var _defaults: DefaultsUrlBridge { DefaultsUrlBridge() }
    #endif
    public static var _defaultsArray: DefaultsKeyedArchiverBridge<[URL]> { DefaultsKeyedArchiverBridge() }
}

public extension DefaultsSerializable where Self: Codable {
    static var _defaults: DefaultsCodableBridge<Self> { DefaultsCodableBridge() }
    static var _defaultsArray: DefaultsCodableBridge<[Self]> { DefaultsCodableBridge() }
}

public extension DefaultsSerializable where Self: RawRepresentable {
    static var _defaults: DefaultsRawRepresentableBridge<Self> { DefaultsRawRepresentableBridge() }
    static var _defaultsArray: DefaultsRawRepresentableArrayBridge<[Self]> { DefaultsRawRepresentableArrayBridge() }
}

public extension DefaultsSerializable where Self: NSCoding {
    static var _defaults: DefaultsKeyedArchiverBridge<Self> { DefaultsKeyedArchiverBridge() }
    static var _defaultsArray: DefaultsKeyedArchiverBridge<[Self]> { DefaultsKeyedArchiverBridge() }
}

extension Dictionary: DefaultsSerializable where Key == String {
    public typealias T = [Key: Value]
    public typealias Bridge = DefaultsObjectBridge<T>
    public typealias ArrayBridge = DefaultsArrayBridge<[T]>
    public static var _defaults: Bridge { Bridge() }
    public static var _defaultsArray: ArrayBridge { ArrayBridge() }
}

extension Array: DefaultsSerializable where Element: DefaultsSerializable {
    public typealias T = [Element.T]
    public typealias Bridge = Element.ArrayBridge
    public typealias ArrayBridge = DefaultsObjectBridge<[T]>
    public static var _defaults: Bridge {
        Element._defaultsArray
    }

    public static var _defaultsArray: ArrayBridge {
        fatalError("Multidimensional arrays are not supported yet")
    }
}
