//
//  PropertyScope.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/14/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import Foundation

final public class PropertyScope<T: Any> {
    private var props = [String: T]()
    private let accessQueue = DispatchQueue(label: "PropertyScopeAccess", attributes: .concurrent)
    public init() {
        
    }
    
    private func key(by object: AnyObject) -> String {
        var k: String = ""
        self.accessQueue.sync {
            k = "\(unsafeBitCast(object, to: Int.self))"
        }
        return k
    }
    
    public func value(_ key: AnyObject) -> T? {
        var val: T?
        let k = self.key(by: key)
        self.accessQueue.sync {
            val = self.props[k] ?? nil
        }
        return val
    }
    
    public func set(_ key: AnyObject, value: T) {
        let k = self.key(by: key)
        self.accessQueue.async(flags: .barrier) {
            self.props[k] = value
        }
    }
    
    public func remove(_ key: AnyObject) {
        let k = self.key(by: key)
        self.accessQueue.async(flags: .barrier) {
            self.props.removeValue(forKey: k)
        }
    }
}
