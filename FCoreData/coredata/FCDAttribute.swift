//
//  FCDAttribute.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/14/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import CoreData

public enum FCDAttributeType {
    case undefined, string, int, int16, int32, int64, decimal, double, float, bool, date, data
    
    case transformable
    case objectID
    
    @available(iOS 11.0, *)
    case uuid
    @available(iOS 11.0, *)
    case uri
    
    var cdAttrType: NSAttributeType {
        switch self {
        case .undefined:
            return .undefinedAttributeType
        case .string:
            return .stringAttributeType
        case .int:
            return .integer64AttributeType
        case .int16:
            return .integer16AttributeType
        case .int32:
            return .integer32AttributeType
        case .int64:
            return .integer64AttributeType
        case .decimal:
            return .decimalAttributeType
        case .double:
            return .doubleAttributeType
        case .float:
            return .floatAttributeType
        case .bool:
            return .booleanAttributeType
        case .date:
            return .dateAttributeType
        case .data:
            return .binaryDataAttributeType
        case .transformable:
            return .transformableAttributeType
        case .objectID:
            return .objectIDAttributeType
        case .uuid:
            return .UUIDAttributeType
        case .uri:
            return .URIAttributeType
        }
    }
}

public struct FCDAttribute {
    public let name: String
    public let type: FCDAttributeType
    public let isOptional: Bool
    public let isIndexed: Bool
    public let defaultValue: Any?
    public init(name: String,
                type: FCDAttributeType,
                isOptional: Bool,
                isIndexed: Bool,
                defaultValue: Any?) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.isIndexed = isIndexed
        self.defaultValue = defaultValue
    }
}
