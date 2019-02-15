//
//  FCoreDataTests.swift
//  FCoreDataTests
//
//  Created by Shohin Tagaev on 2/13/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import CoreData
import XCTest
@testable import FCoreData

let dbm = FCoreDataManager(modelName: "test")

final class Student {
    let id: Int
    let name: String
    init(id: Int,
         name: String) {
        self.id = id
        self.name = name
    }
}

final class Group {
    let id: Int
    let name: String
    let students: Array<Student>
    init(id: Int,
         name: String,
         students: Array<Student>) {
        self.id = id
        self.name = name
        self.students = students
    }
}

extension Student: FCDEntity {
    enum AttrsNames: String {
        case id = "id", name = "name"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = nil
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1),
                  name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""))
    }
}

extension Group: FCDEntity {
    enum AttrsNames: String {
        case id = "id", name = "name"
        var value: String {
            return self.rawValue
        }
    }
    
    enum RelationsNames: String {
        case students = "students"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = [FCDRelation(name: RelationsNames.students.value, type: .many, deleteRule: .cascadeDeleteRule, inverse: nil)]
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name,
                RelationsNames.students.value: NSMutableSet(array: self.students.map({ (st) -> FManagedObject in
                    let mo = FManagedObject(entity: NSEntityDescription.entity(forEntityName: Student.entityName, in: dbm.managedObjectContext)!, insertInto: dbm.managedObjectContext)
                    mo.setValue(st.id, forKey: Student.AttrsNames.id.value)
                    mo.setValue(st.name, forKey: Student.AttrsNames.name.value)
                    return mo
                }))
        ]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1),
                  name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""),
                  students: managedObject.mutableSetValue(forKey: RelationsNames.students.value).map({ (mo) -> Student in
                    return Student(managedObject: mo as! FManagedObject)
                  }))
    }
}

class FCoreDataTests: XCTestCase {
    private var moc: FManagedObjectContext!
    
    override func setUp() {
        dbm.set(configManagedModel: { (mo) in
            let se = Student.schemeEntity()
            let gr = Group.schemeEntity()
            Group.set(relationDestination: Student.schemeEntity(), relationName: Group.RelationsNames.students.value)
            let entities = [se, gr]
            mo.entities = entities
        })
        self.moc = dbm.managedObjectContext
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsert() {
        let students1 = [Student(id: 1, name: "Student1"),
                        Student(id: 2, name: "Student2"),
                        Student(id: 3, name: "Student3")]
        let students2 = [Student(id: 4, name: "Student4"),
                         Student(id: 5, name: "Student5"),
                         Student(id: 6, name: "Student6"),]
        let students = students1 + students2
        Student.insert(context: self.moc, items: students)
        
        let students3 = [Student(id: 7, name: "Student7"),
                         Student(id: 8, name: "Student8"),
                         Student(id: 9, name: "Student9"),]
        
        let groups = [Group(id: 1, name: "210-10", students: students1),
                      Group(id: 2, name: "211-10", students: students2),
                      Group(id: 3, name: "212-10", students: students3)]
        Group.insert(context: self.moc, items: groups)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
