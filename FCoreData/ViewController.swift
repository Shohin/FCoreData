//
//  ViewController.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/13/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import UIKit
import CoreData

final class Test {
    let id: Int
    let name: String
    let attr: String?
    init(id: Int,
         name: String,
         attr: String?) {
        self.id = id
        self.name = name
        self.attr = attr
    }
}

extension Test: FCDEntity {
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    
    enum AttrsNames: String {
        case id = "id", name = "name", attr = "attr"
        var value: String {
            return self.rawValue
        }
    }
    convenience init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1),
                  name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""),
                  attr: managedObject.value(forKey: AttrsNames.attr.value) as? String)
        print("OBJID: \(managedObject.objectID)")
    }
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name,
                AttrsNames.attr.value: self.attr]
    }
    
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.attr.value, type: .string, isOptional: true, isIndexed: false, defaultValue: nil)]
    
    static var entityName: String {
        return "test"
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let cdm = FCoreDataManager(modelName: "fcoredata")
        let moc = cdm.managedObjectContext
//        let entityName = "test"
//        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc) else {
//            fatalError("Do not find \(entityName) entity")
//        }
////        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
//
//        let mo = NSManagedObject(entity: entity, insertInto: moc)
//        print("Insert ID: \(mo.objectID)")
//        mo.setValue(1, forKey: "id")
//        mo.setValue("Test name", forKey: "name")
//        mo.setValue("Test attr", forKey: "attr")
//        do {
//            try moc.save()
//        } catch let error as NSError  {
//            print("[ERROR] Could not save \(error), \(error.userInfo)")
//        }
//
//        let items = Test.all(context: moc)
//        print(Test.entityName)
//        for item in items {
//            print("id: \(item.id), name: \(item.name), attr: \(item.attr ?? "Def attr")")
//            print("MOID: \(item.managedObjectID)")
//        }
//
//        let t = Test(id: 2, name: "TestName", attr: "Attr2")
//        t.managedObjectID = mo.objectID
//        t.delete(context: moc)
//
//        items.first?.bacthUpdate(context: moc, updateObject: t, predicate: nil, isReflectChanges: true)
//
//        let mo1 = NSManagedObject(entity: entity, insertInto: moc)
//        print("Insert ID: \(mo1.objectID)")
//        mo1.setValue(10, forKey: "id")
//        mo1.setValue("Test name1", forKey: "name")
//        mo1.setValue("Test attr1", forKey: "attr")
//        do {
//            try moc.save()
//        } catch let error as NSError  {
//            print("[ERROR] Could not save \(error), \(error.userInfo)")
//        }
//
//        let t1 = Test(id: 10, name: "Test name1", attr: "Test attr1")
//        t1.managedObjectID = mo1.objectID
//        t1.save(context: moc)
//
//        let items1 = Test.all(context: moc)
//        for item in items1 {
//            print("id: \(item.id), name: \(item.name), attr: \(item.attr ?? "Def attr")")
//            print("MOID: \(item.managedObjectID)")
//        }
//
//        let t2 = Test(id: 11, name: "Test inser", attr: "Test inser attr")
//        t2.insert(context: moc)
        
        
        
        let saveItems = [Test(id: 100, name: "RName123", attr: "RAttr12"),
                     Test(id: 101, name: "RName23", attr: "RAttr23"),
//                     Test(id: 102, name: "Name3", attr: "Attr1"),
//                     Test(id: 103, name: "Name4", attr: "Attr1"),
//                     Test(id: 104, name: "Name5", attr: "Attr1"),
//                     Test(id: 105, name: "Name6", attr: "Attr1")
        ]
        let ids = saveItems.map { (t) -> Int in
            return t.id
        }
        let pr = NSPredicate(format: "Self.id IN %@", ids)
        Test.save(context: moc, items: saveItems, predicate: pr)
        
        let sort = NSSortDescriptor(key: "id", ascending: true)
        let items1 = Test.all(context: moc, predicate: pr, sortDescriptors: [sort], limit: 1, offset: 1)
        for item in items1 {
            print("id: \(item.id), name: \(item.name), attr: \(item.attr ?? "Def attr")")
        }
    }


}

