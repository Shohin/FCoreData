//
//  FCDRelation.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/15/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import CoreData

public enum FCDRelationType {
    case one, many
}

final public class FCDRelation {
    private(set) public var destinationEntity: FEntityDescription!
    public let name: String
    public let type: FCDRelationType
    public let deleteRule: FDeleteRule
    public let inverse: FCDRelation?
    public init(name: String,
                type: FCDRelationType,
                deleteRule: FDeleteRule,
                inverse: FCDRelation?) {
        self.name = name
        self.type = type
        self.deleteRule = deleteRule
        self.inverse = inverse
    }
    
    public func set(destinationEntity: FEntityDescription) {
        self.destinationEntity = destinationEntity
    }
}
