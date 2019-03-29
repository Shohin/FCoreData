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
    public init() {
        
    }
    
    private func key(by object: AnyObject) -> String {
        let k = "\(unsafeBitCast(object, to: Int.self))"
        return k
    }
    
    public func value(_ key: AnyObject) -> T? {
        let k = self.key(by: key)
        return self.props[k] ?? nil
    }
    
    public func set(_ key: AnyObject, value: T) {
        let k = self.key(by: key)
        self.props[k] = value
    }
    
    public func remove(_ key: AnyObject) {
        let k = self.key(by: key)
        self.props.removeValue(forKey: k)
    }
}
