//
//  FCDEntity.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/13/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import CoreData

public protocol FCDEntity: class {
    static var managedObjectIDScope: PropertyScope<FManagedObjectID> {get}
    static var entityName: String {get}
    static var entityAttributes: Array<FCDAttribute> {get}
    static var entityRelations: Array<FCDRelation>? {get}
    var attrValuesByName: Dictionary<String, Any?> {get}
    init(managedObject: FManagedObject)
}

public extension FCDEntity {
    public var managedObjectID: FManagedObjectID? {
        get {
            return Self.managedObjectIDScope.get(self as AnyObject)
        }
        set {
            if let nw = newValue {
                Self.managedObjectIDScope.set(self as AnyObject, value: nw)
            }
        }
    }
}

public extension FCDEntity {
    private func entity(context: FManagedObjectContext) -> NSEntityDescription {
        let name = type(of: self).entityName
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            fatalError("Entity not found: \(name)")
        }
        return entity
    }
    
    private static func removeMOID(obj: Self) {
        self.managedObjectIDScope.remove(by: obj as AnyObject)
    }
    
    @discardableResult
    private static func _save(context: FManagedObjectContext) -> Bool {
        do {
            try context.save()
            return true
        } catch let error as NSError  {
            print("[ERROR] Could not save \(error), \(error.userInfo)")
        }
        return false
    }
    
    public static var entityName: String {
        return String(describing: self)
    }
    
    public static func set(relationDestination: FEntityDescription, relationName: String) {
        guard let rls = self.entityRelations,
            !rls.isEmpty, let rl = rls.first(where: { (r) -> Bool in
                return r.name == relationName
            }) else {
            return
        }
        
        rl.set(destinationEntity: relationDestination)
    }
    
    public static func schemeEntity() -> FEntityDescription {
        let entity = FEntityDescription()
        entity.name = self.entityName
        
        func attribute(from attr: FCDAttribute) -> NSAttributeDescription {
            let newAttr = NSAttributeDescription()
            newAttr.name = attr.name
            newAttr.attributeType = attr.type.cdAttrType
            newAttr.isOptional = attr.isOptional
            if attr.isIndexed {
                if #available(iOS 11.0, *) {
                    //TODO:
//                    let attributeCreatedDate = NSAttributeDescription()
//                    attributeCreatedDate.name = #keyPath(PostEntity.createdDate)
//                    attributeCreatedDate.attributeType = .dateAttributeType
//                    attributeCreatedDate.isOptional = false
//
//                    let attributeID = NSAttributeDescription()
//                    attributeID.name = #keyPath(PostEntity.id)
//                    attributeID.attributeType = .stringAttributeType
//                    attributeID.isOptional = false
//
//                    ...
//
//                    let attributeVideoURL = NSAttributeDescription()
//                    attributeVideoURL.name = #keyPath(PostEntity.videoURL)
//                    attributeVideoURL.attributeType = .URIAttributeType
//                    attributeVideoURL.isOptional = true
//
//                    let indexDescription1 = NSFetchIndexElementDescription(property: attributeCreatedDate, collationType: .binary)
//                    indexDescription1.isAscending = true
//                    let index1 = NSFetchIndexDescription(name: "com_mc_index_post_createdDate", elements: [indexDescription1])
//
//                    let indexDescription2 = NSFetchIndexElementDescription(property: attributeID, collationType: .binary)
//                    indexDescription2.isAscending = true
//                    let index2 = NSFetchIndexDescription(name: "com_mc_index_post_id", elements: [indexDescription2])
//
//                    let entity = NSEntityDescription()
//                    entity.name = PostEntity.entityName
//                    entity.managedObjectClassName = PostEntity.entityClassName
//                    entity.properties = [attributeCreatedDate, attributeID, attributeVideoURL, ...]
//                    entity.renamingIdentifier = "com.mc.entity-post"
//                    entity.indexes = [index1, index2]
                    
//                    NSFetchIndexElementDescription(property: idAttr, collationType: .binary)
//                    NSFetchIndexDescription(name: <#T##String#>, elements: <#T##[NSFetchIndexElementDescription]?#>)
//                    entity.indexes = [idAttr]
                } else {
                    newAttr.isIndexed = true
                }
            }
            if let defVal = attr.defaultValue {
                newAttr.defaultValue = defVal
            }
            return newAttr
        }
        
        func relation(from rl: FCDRelation) -> NSRelationshipDescription {
            let r = NSRelationshipDescription()
            r.name = rl.name
            r.deleteRule = rl.deleteRule
//            r.destinationEntity = rl.destinationEntity
            switch rl.type {
            case .one:
                r.minCount = 0
                r.maxCount = 1
            case .many:
                r.minCount = 0
                r.maxCount = 0
            }
            if let irl = rl.inverse {
                r.inverseRelationship = relation(from: irl)
            }
            return r
        }
        
        var props: Array<NSPropertyDescription> = Self.entityAttributes.map { (attr) -> NSAttributeDescription in
            return attribute(from: attr)
        }
        
        if let rls = Self.entityRelations,
            !rls.isEmpty {
            for rl in rls {
                props.append(relation(from: rl))
            }
        }
        
        entity.properties = props
        return entity
    }
    
    public func insert(context: FManagedObjectContext) {
        let entity = self.entity(context: context)
        let mo = FManagedObject(entity: entity, insertInto: context)
        for (key, value) in self.attrValuesByName {
            if value == nil,
                let prop = mo.entity.propertiesByName[key] {
                assert(prop.isOptional, "Required value in :\(prop.name)")
            }
            mo.setValue(value, forKey: key)
        }
        Self._save(context: context)
    }
    
    //Referential Integrity: Referential integrity will not be maintained between related objects. As an example, setting an employee’s department will not in turn update the array of employees on the department object. In light of this, its typically best to avoid using a batch update request on properties that reference other NSManagedObjects.
    public func bacthUpdate(context: FManagedObjectContext,
                            updateObject: Self,
                            predicate: NSPredicate?,
                            isReflectChanges: Bool) {
        let entity = self.entity(context: context)
        let br = NSBatchUpdateRequest(entity: entity)
        br.predicate = predicate
        br.propertiesToUpdate = updateObject.attrValuesByName as [AnyHashable : Any]
        br.resultType = .updatedObjectIDsResultType
        do {
            guard let res: NSBatchUpdateResult = try context.execute(br) as? NSBatchUpdateResult else {
                fatalError("Error on executing batch update request.")
            }
            guard let objIds = res.result as? [NSManagedObjectID] else {
                fatalError("Error on retrieving batch update result.")
            }
            print("Result: \(objIds)")
            if isReflectChanges {
                for objId in objIds {
                    let mo = context.object(with: objId)
                    if !mo.isFault {
                        context.refresh(mo, mergeChanges: true) //TODO: mergeChanges true or false
                    }
                }
            }
        } catch {
            fatalError("Error on batch update. Reason: \(error)")
        }
    }
    
    //removed if exists and updated, else inserted
    //it worked correct when managedObjectID is not null
    public func save(context: FManagedObjectContext) {
        if let _ = self.managedObjectID {
            self.delete(context: context)
        }
        self.insert(context: context)
    }
    
    //without managedObjectID crashed
    public func delete(context: FManagedObjectContext) {
        guard let moID = self.managedObjectID else {
            fatalError("Object not found for deleting!")
        }
        let mo = context.object(with: moID)
        context.delete(mo)
        if Self._save(context: context) {
            Self.removeMOID(obj: self)
        }
    }
    
    public static func delete(context: FManagedObjectContext,
                              items: Array<Self>) {
        for item in items {
            item.delete(context: context)
        }
    }
    
    /// If predicate is nil remove all datas
    public static func delete(context: FManagedObjectContext,
                              predicate: NSPredicate?) {
        let name = self.entityName
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.predicate = predicate
        
        do {
            guard let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                fatalError("Error on retrieving fetching results: \(name)")
            }
            
            for mo in fetchResults {
                context.delete(mo)
            }
            
            if Self._save(context: context) {
                //TODO: Must remove managed object ids to.
            }
        } catch {
            fatalError("Error on fetching \(name). Reason: \(error)")
        }
    }
    
    public static func save(context: FManagedObjectContext,
                            items: Array<Self>,
                            predicate: NSPredicate?) {
        let name = self.entityName
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        fetchRequest.predicate = predicate
        
        do {
            guard let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject] else {
                fatalError("Error on retrieving fetching results: \(name)")
            }
            for fr in fetchResults {
                context.delete(fr)
            }
            self.insert(context: context, items: items)
        } catch {
            fatalError("Error on fetching \(name). Reason: \(error)")
        }
    }
    
    public static func insert(context: FManagedObjectContext,
                              items: Array<Self>) {
        for item in items {
            item.insert(context: context)
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
                let obj = Self(managedObject: mo)
                obj.managedObjectID = mo.objectID
                return obj
            })
        } catch {
            fatalError("Error on fetching \(name). Reason: \(error)")
        }
    }
}
