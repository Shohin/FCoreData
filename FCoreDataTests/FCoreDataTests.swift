//
//  FCoreDataTests.swift
//  FCoreDataTests
//
//  Created by Shohin Tagaev on 2/13/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

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
        case students1 = "students1"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = [
        FCDRelation(name: RelationsNames.students.value, destinationType: Student.self, type: .many, deleteRule: .cascadeDeleteRule, isOptional: true, inverseName: nil),
        FCDRelation(name: RelationsNames.students1.value, destinationType: Student.self, type: .many, deleteRule: .cascadeDeleteRule, isOptional: true, inverseName: nil)]
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name,
                RelationsNames.students.value: NSMutableSet(array: self.students.map({ (st) -> FManagedObject in
                    let mo = Student.insertIntoManagedObject(context: dbm.managedObjectContext)
                    mo.setValue(st.id, forKey: Student.AttrsNames.id.value)
                    mo.setValue(st.name, forKey: Student.AttrsNames.name.value)
                    return mo
                })),
                RelationsNames.students1.value: NSMutableSet(array: self.students.filter({ (st) -> Bool in
                    return st.id > 5
                }).map({ (st) -> FManagedObject in
                    let mo = Student.insertIntoManagedObject(context: dbm.managedObjectContext)
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

final class A {
    let id: Int
    init(id: Int) {
        self.id = id
    }
}

final class B {
    let name: String
    let a: A
    init(name: String,
         a: A) {
        self.name = name
        self.a = a
    }
}

extension A: FCDEntity {
    enum AttrsNames: String {
        case id = "id"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = nil
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1))
    }
}

extension B: FCDEntity {
    enum AttrsNames: String {
        case name = "name"
        var value: String {
            return self.rawValue
        }
    }
    
    enum RelationsNames: String {
        case a = "a"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = [FCDRelation(name: RelationsNames.a.value, destinationType: A.self, type: .one, deleteRule: .cascadeDeleteRule, isOptional: true, inverseName: nil)]
    
    var attrValuesByName: Dictionary<String, Any?> {
        let mo = A.insertIntoManagedObject(context: dbm.managedObjectContext)
        mo.setValue(self.a.id, forKey: A.AttrsNames.id.value)
        return [AttrsNames.name.value: self.name,
                RelationsNames.a.value: mo
        ]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""),
                  a: A(managedObject: managedObject.value(forKey: RelationsNames.a.value) as! FManagedObject))
    }
}

final class Child {
    let id: Int
    let name: String
    let parent: Parent?
    init(id: Int,
         name: String,
         parent: Parent?) {
        self.id = id
        self.name = name
        self.parent = parent
    }
}

final class Parent {
    let title: String
    let childs: Array<Child>
    init(title: String,
         childs: Array<Child>) {
        self.title = title
        self.childs = childs
    }
}

extension Child: FCDEntity {
    enum AttrsNames: String {
        case id = "id", name = "name"
        var value: String {
            return self.rawValue
        }
    }
    
    enum RelationsNames: String {
        case parent = "parent"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.id.value, type: .int, isOptional: false, isIndexed: true, defaultValue: nil),
        FCDAttribute(name: AttrsNames.name.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = [FCDRelation(name: RelationsNames.parent.value, destinationType: Parent.self, type: .one, deleteRule: .noActionDeleteRule, isOptional: false, inverseName: nil)]
    
    var attrValuesByName: Dictionary<String, Any?> {
        let pMO = Parent.insertIntoManagedObject(context: dbm.managedObjectContext)
        pMO.setValue(self.parent?.title, forKey: Parent.AttrsNames.title.value)
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name,
                RelationsNames.parent.value: self.parent != nil ? pMO : nil]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(id: (managedObject.value(forKey: AttrsNames.id.value) as? Int ?? -1),
                  name: (managedObject.value(forKey: AttrsNames.name.value) as? String ?? ""),
                  parent: Parent(title: "Title1", childs: []))
    }
}

extension Parent: FCDEntity {
    enum AttrsNames: String {
        case title = "title"
        var value: String {
            return self.rawValue
        }
    }
    
    enum RelationsNames: String {
        case childs = "childs"
        case inverseChild = "parent"
        var value: String {
            return self.rawValue
        }
    }
    
    static let managedObjectIDScope: PropertyScope<FManagedObjectID> = PropertyScope<FManagedObjectID>()
    static let entityAttributes: Array<FCDAttribute> = [
        FCDAttribute(name: AttrsNames.title.value, type: .string, isOptional: false, isIndexed: true, defaultValue: nil)]
    static let entityRelations: Array<FCDRelation>? = [
        FCDRelation(name: RelationsNames.childs.value, destinationType: Child.self, type: .many, deleteRule: .cascadeDeleteRule, isOptional: true, inverseName: RelationsNames.inverseChild.value)]
    
    var attrValuesByName: Dictionary<String, Any?> {
        return [AttrsNames.title.value: self.title,
                RelationsNames.childs.value: NSMutableSet(array: self.childs.map({ (ch) -> FManagedObject in
                    let mo = Child.insertIntoManagedObject(context: dbm.managedObjectContext)
                    mo.setValue(ch.id, forKey: Child.AttrsNames.id.value)
                    mo.setValue(ch.name, forKey: Child.AttrsNames.name.value)
                    return mo
                }))
        ]
    }
    
    convenience init(managedObject: FManagedObject) {
        self.init(title: (managedObject.value(forKey: AttrsNames.title.value) as? String ?? ""),
                  childs: managedObject.mutableSetValue(forKey: RelationsNames.childs.value).map({ (mo) -> Child in
                    return Child(managedObject: mo as! FManagedObject)
                  }))
    }
}

class FCoreDataTests: XCTestCase {
    private var moc: FManagedObjectContext!
    
    override func setUp() {
        dbm.set(configManagedModel: { (mo) in
//            let se = Student.schemeEntity()
//            Group.set(relationDestination: se, relationName: Group.RelationsNames.students.value)
//            Group.set(relationDestination: se, relationName: Group.RelationsNames.students1.value)
//            let gr = Group.schemeEntity()
//            gr.relationshipsByName[Group.RelationsNames.students.value]?.destinationEntity = se
//            let a = A.schemeEntity()
//            B.set(relationDestination: a, relationName: B.RelationsNames.a.value)
//            let b = B.schemeEntity()
//            let entities = [se, gr, a, b]
//            mo.entities = entities
//            mo.entities.first(where: { (en) -> Bool in
//                return en.name == Group.entityName
//            })?.relationshipsByName[Group.RelationsNames.students.value]?.destinationEntity = se
//            mo.entities.first(where: { (en) -> Bool in
//                return en.name == Group.entityName
//            })?.relationshipsByName[Group.RelationsNames.students1.value]?.destinationEntity = se
            let sc = FCDSchemeCreator(managedObjectModel: mo, entityTypes: [Student.self, Group.self, A.self, B.self, Child.self, Parent.self])
            sc.create()
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
//        let students = students1 + students2
//        Student.insert(context: self.moc, items: students)
        
        let students3 = [Student(id: 7, name: "Student7"),
                         Student(id: 8, name: "Student8"),
                         Student(id: 9, name: "Student9"),]
        
        let groups = [Group(id: 1, name: "210-10", students: students1),
                      Group(id: 2, name: "211-10", students: students2),
                      Group(id: 3, name: "212-10", students: students3)]
        Group.insert(context: self.moc, items: groups)
        
        for item in Group.all(context: self.moc) {
            print(item.id)
            print(item.name)
            for st in item.students {
                print(st.id)
                print(st.name)
            }
        }
        
        let a = A(id: 1)
//        A.insert(context: moc, items: [a])
        
        let b = B(name: "B", a: a)
        B.insert(context: moc, items: [b])
        
        for item in B.all(context: self.moc) {
            print(item.name)
            print(item.a.id)
        }
    }
    
    func testParentChild() {
        let moc = dbm.managedObjectContext
        let childs = [
            Child(id: 1, name: "Child", parent: nil),
            Child(id: 2, name: "Child1", parent: nil),
            Child(id: 3, name: "Child2", parent: nil),
            Child(id: 4, name: "Child3", parent: nil),
            Child(id: 5, name: "Child4", parent: nil),]
        
        let p = Parent(title: "Title", childs: childs)
        p.insert(context: moc)
        
        print("Parent")
        for item in Parent.all(context: moc) {
            print("Title: \(item.title)")
            print("Parent chidls")
            for ch in item.childs {
                print("Id: \(ch.id)")
                print("Name: \(ch.name)")
                print("Parent: \(ch.parent?.title ?? "No parent")")
            }
        }
        
        let p1 = Parent(title: "Title1", childs: [])
        
        let ch = Child(id: 100, name: "Child100", parent: p1)
        ch.insert(context: moc)
        
        let p2 = Parent(title: "Title2", childs: [])
        let ch1 = Child(id: 101, name: "Child101", parent: p2)
        ch1.insert(context: moc)
        
        let p3 = Parent(title: "Title3", childs: [])
        let ch2 = Child(id: 102, name: "Child102", parent: p3)
        ch2.insert(context: moc)
        
        print("Childs")
        for ch in Child.all(context: moc, predicate: NSPredicate(format: "\(Child.AttrsNames.id.value) > %d", 99)) {
            print("Id: \(ch.id)")
            print("Name: \(ch.name)")
            print("Parent: \(ch.parent?.title ?? "No parent")")
        }
    }
}
