# FCoreData
Forob Core Data

* __Fully clean code Core Data.__
* __Works only on main thread. (thread safe and multi threading in plan)__
* __Creation and manipulation model from source code.__

## __Classes(models):__

```swift
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

```

## __Core Data usage:__

```swift
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

    func attrValuesByName(context: FManagedObjectContext) -> Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name]
    }
    
    func newManagedObject(context: FManagedObjectContext) -> FManagedObject {
        let mo = Student.insertIntoManagedObject(context: context)
        mo.setValue(self.id, forKey: AttrsNames.id.value)
        mo.setValue(self.name, forKey: AttrsNames.name.value)
        return mo
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
    
    func attrValuesByName(context: FManagedObjectContext) -> Dictionary<String, Any?> {
        return [AttrsNames.id.value: self.id,
                AttrsNames.name.value: self.name,
                RelationsNames.students.value: NSMutableSet(array: self.students.map({ (st) -> FManagedObject in
                    return st.newManagedObject(context: context)
                })),
                RelationsNames.students1.value: NSMutableSet(array: self.students.filter({ (st) -> Bool in
                    return st.id > 5
                }).map({ (st) -> FManagedObject in
                    return st.newManagedObject(context: context)
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

```

## __Creation:__

```swift
let dbm = FCoreDataManager(modelName: "test", migrationType: .restore)
```

## __Core Data managed object model createion:__

```swift

dbm.set(configManagedModel: { (mo) in
    let sc = FCDSchemeCreator(managedObjectModel: mo, entityTypes: [Student.self, Group.self])
    sc.create()
})
        
let moc: FManagedObjectContext = dbm.managedObjectContext;

```

## __Data insertion:__

```swift
let students1 = [Student(id: 1, name: "Student1"),
                 Student(id: 2, name: "Student2"),
                 Student(id: 3, name: "Student3")]
let students2 = [Student(id: 4, name: "Student4"),
                Student(id: 5, name: "Student5"),
                Student(id: 6, name: "Student6"),]
                         
let students3 = [Student(id: 7, name: "Student7"),
                 Student(id: 8, name: "Student8"),
                 Student(id: 9, name: "Student9"),]

let groups = [Group(id: 1, name: "210-10", students: students1),
              Group(id: 2, name: "211-10", students: students2),
              Group(id: 3, name: "212-10", students: students3)]
Group.insert(context: self.moc, items: groups)

```

## __Data retrieving:__

```swift
for item in Group.all(context: self.moc) {
    print(item.id)
    print(item.name)
    for st in item.students {
        print(st.id)
        print(st.name)
    }
}

```

## __Data retrieving options:__

```swift

Group.all(context: self.moc, predicate: NSPredicate?, sortDescriptors: Array<NSSortDescriptor>?, limit: Int?, offset: Int?)

```

## __Data deletion options:__

```swift

Group.delete(context: self.moc, predicate: NSPredicate?)

```
