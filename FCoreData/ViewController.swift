//
//  ViewController.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/13/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import UIKit
import CoreData

struct Test {
    let id: Int
    let name: String
    let attr: String?
}

extension Test: FCDEntity {
    enum AttrsNames: String {
        case id = "id", name = "name", attr = "attr"
        var value: String {
            return self.rawValue
        }
    }
    init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1),
                  name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""),
                  attr: managedObject.value(forKey: AttrsNames.attr.value) as? String)
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
        let entityName = "test"
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc) else {
            fatalError("Do not find \(entityName) entity")
        }
        //        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        let mo = NSManagedObject(entity: entity, insertInto: moc)
        mo.setValue(1, forKey: "id")
        mo.setValue("Test name", forKey: "name")
        mo.setValue("Test attr", forKey: "attr")
        do {
            try moc.save()
        } catch let error as NSError  {
            print("[ERROR] Could not save \(error), \(error.userInfo)")
        }
        
        print("props")
        print(entity.properties)
        print("props by name")
        print(entity.propertiesByName)
        print("attrs by name")
        print(entity.attributesByName)
        
        let items = Test.all(context: moc)
        print(Test.entityName)
        for item in items {
            print(item)
        }
        
        for (key, value) in Test(id: -1, name: "", attr: nil).attrValuesByName {
            guard let v = value else {
                continue
            }
            print(type(of: v))
        }
    }


}

