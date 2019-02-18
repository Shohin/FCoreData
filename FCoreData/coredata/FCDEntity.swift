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
    init(managedObject: FManagedObject)
    func attrValuesByName(context: FManagedObjectContext) -> Dictionary<String, Any?>
    func newManagedObject(context: FManagedObjectContext) -> FManagedObject
}

public extension FCDEntity {
    func newManagedObject(context: FManagedObjectContext) -> FManagedObject {
        return Self.insertIntoManagedObject(context: context)
    }
}

public extension FCDEntity {
    public var managedObjectID: FManagedObjectID? {
        get {
            return Self.managedObjectIDScope.value(self as AnyObject)
        }
        set {
            if let nw = newValue {
                Self.managedObjectIDScope.set(self as AnyObject, value: nw)
            }
        }
    }
}

public extension FCDEntity {
    private static func entity(context: FManagedObjectContext) -> NSEntityDescription {
        let name = self.entityName
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            fatalError("Entity not found: \(name)")
        }
        return entity
    }
    
    private static func removeMOID(obj: Self) {
        self.managedObjectIDScope.remove(obj as AnyObject)
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
    
    public func insert(context: FManagedObjectContext) {
        let entity = Self.entity(context: context)
        let mo = FManagedObject(entity: entity, insertInto: context)
        let attrs = self.attrValuesByName(context: context)
        for (key, value) in attrs {
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
        let entity = Self.entity(context: context)
        let br = NSBatchUpdateRequest(entity: entity)
        br.predicate = predicate
        br.propertiesToUpdate = updateObject.attrValuesByName(context: context) as [AnyHashable : Any]
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
    
    public static func insertIntoManagedObject(context: FManagedObjectContext) -> FManagedObject {
        let entity = self.entity(context: context)
        let mo = FManagedObject(entity: entity, insertInto: context)
        return mo
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
