//
//  FCDEntity.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/13/19.
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

public protocol FCDEntity {
    static var entityName: String {get}
    static var entityAttributes: Array<FCDAttribute> {get}
    init(managedObject: FManagedObject)
    var attrValuesByName: Dictionary<String, Any?> {get}
}

public extension FCDEntity {
    private func entity(context: FManagedObjectContext) -> NSEntityDescription {
        let name = type(of: self).entityName
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            fatalError("Entity not found: \(name)")
        }
        return entity
    }
    
    public static var entityName: String {
        return String(describing: self)
    }
    
    public func insert(context: FManagedObjectContext) {
        let entity = self.entity(context: context)
        let mo = FManagedObject(entity: entity, insertInto: context)
        for (key, value) in self.attrValuesByName {
            if value == nil,
                let prop = mo.entity.propertiesByName[key] {
                assert(!prop.isOptional, "Required value in :\(prop.name)")
            }
            mo.setValue(value, forKey: key)
        }
        do {
            try context.save()
        } catch let error as NSError  {
            print("[ERROR] Could not save \(error), \(error.userInfo)")
        }
    }
    
    public static func all(context: FManagedObjectContext,
                           predicate: NSPredicate? = nil,
                           sortDescriptors: Array<NSSortDescriptor>? = nil,
                           limit: Int? = nil,
                           offset: Int? = nil) -> Array<Self> {
        let name = self.entityName
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let l = limit {
            fetchRequest.fetchLimit = l
        }
        
        if let o = offset {
            fetchRequest.fetchOffset = o
        }
        
        do {
            guard let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                fatalError("Error on retrieving fetching results: \(name)")
            }
            return fetchResults.map({ (mo) -> Self in
                return Self(managedObject: mo)
            })
        } catch {
            fatalError("Error on fetching \(name). Reason: \(error)")
        }
    }
}
