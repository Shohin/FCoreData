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
    public let name: String
    public let destinationType: FCDEntity.Type
    public let type: FCDRelationType
    public let deleteRule: FDeleteRule
    public let isOptional: Bool
    public let inverseName: String?
    public init(name: String,
                destinationType: FCDEntity.Type,
                type: FCDRelationType,
                deleteRule: FDeleteRule,
                isOptional: Bool,
                inverseName: String?) {
        self.name = name
        self.destinationType = destinationType
        self.type = type
        self.deleteRule = deleteRule
        self.isOptional = isOptional
        self.inverseName = inverseName
    }
}

extension FCDRelation: Equatable {
    public static func == (lhs: FCDRelation, rhs: FCDRelation) -> Bool {
        return lhs.name == rhs.name
            && lhs.type == rhs.type
            && lhs.deleteRule == rhs.deleteRule
    }
}
