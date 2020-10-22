//
//  JSContext+Extensions.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/22/20.
//

import Foundation
import JavaScriptCore

extension JSContext {
    subscript(key: String) -> Any {
        get {
            return self.objectForKeyedSubscript(key)
        }
        set{
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}

@objc protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

class JSConsole: NSObject, JSConsoleExports {
    class func log(_ msg: String) {
        print(msg)
    }
}

@objc protocol JSPromiseExports: JSExport {
    func then(_ resolve: JSValue) -> JSPromise?
    func `catch`(_ reject: JSValue) -> JSPromise?
    func doResolve() -> JSPromise?
}

class JSPromise: NSObject, JSPromiseExports {
    var resolve: JSValue?
    var reject: JSValue?
    var next: JSPromise?
    var timer: Timer?
    
    func then(_ resolve: JSValue) -> JSPromise? {
        self.resolve = resolve
        
        self.next = JSPromise()
        
        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil
        
        return self.next
    }
    
    func `catch`(_ reject: JSValue) -> JSPromise? {
        self.reject = reject
        
        self.next = JSPromise()
        
        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil
        
        return self.next
    }
    
    func fail(error: String) {
        if let reject = reject {
            reject.call(withArguments: [error])
        } else if let next = next {
            next.fail(error: error)
        }
    }
    
    func success(value: Any?) {
        guard let resolve = resolve else { return }
        var result:JSValue?
        if let value = value  {
            result = resolve.call(withArguments: [value])
        } else {
            result = resolve.call(withArguments: [])
        }

        guard let next = next else { return }
        if let result = result {
            if result.isUndefined {
                next.success(value: nil)
                return
            } else if (result.hasProperty("isError")) {
                next.fail(error: result.toString())
                return
            }
        }
        
        next.success(value: result)
    }
    
    func doResolve() -> JSPromise? {
        self.next = nil
        return self.next
    }
}

extension JSContext {
    static var plus:JSContext? {
        let jsMachine = JSVirtualMachine()
        guard let jsContext = JSContext(virtualMachine: jsMachine) else {
            return nil
        }
        
        jsContext.evaluateScript("""
            Error.prototype.isError = () => {return true}
        """)
        jsContext["console"] = JSConsole.self
        jsContext["Promise"] = JSPromise.self
        
        let fetch:@convention(block) (String)->JSPromise? = { link in
            let promise = JSPromise()
            promise.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {timer in
                timer.invalidate()
                
                if let url = URL(string: link) {
                    URLSession.shared.dataTask(with: url){ (data, response, error) in
                        if let error = error {
                            promise.fail(error: error.localizedDescription)
                        } else if
                            let data = data,
                            let string = String(data: data, encoding: String.Encoding.utf8) {
                            promise.success(value: string)
                        } else {
                            promise.fail(error: "\(url) is empty")
                        }
                        }.resume()
                } else {
                    promise.fail(error: "\(link) is not url")
                }
            }
            
            return promise
        }
        jsContext["fetch"] = unsafeBitCast(fetch, to: JSValue.self)
        
        return jsContext
    }
}
