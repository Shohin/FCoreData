//
//  FCDSchemeCreator.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/17/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import CoreData

final public class FCDSchemeCreator {
    public let managedObjectModel: FManagedObjectModel
    public let entityTypes: Array<FCDEntity.Type>
    public init(managedObjectModel: FManagedObjectModel,
                entityTypes: Array<FCDEntity.Type>) {
        self.managedObjectModel = managedObjectModel
        self.entityTypes = entityTypes
    }
    
    public func create() {
        let entities = self.entityTypes.map { (e) -> FEntityDescription in
            return self.newEntity(type: e)
        }
        
        for eTy in self.entityTypes {
            guard let rels = eTy.entityRelations,
                !rels.isEmpty else {
                    continue
            }
            for rl in rels {
                let destEntity = entities.first { (en) -> Bool in
                    return en.name == rl.destinationType.entityName
                }
                let ent = entities.first { (en) -> Bool in
                    return eTy.entityName == en.name
                }
                ent?.relationshipsByName[rl.name]?.destinationEntity = destEntity
                if let invName = rl.inverseName {
                    ent?.relationshipsByName[rl.name]?.inverseRelationship = destEntity?.relationshipsByName[invName]
                }
            }
        }
    
        self.managedObjectModel.entities = entities
    }
    
    private func newEntity(type: FCDEntity.Type) -> FEntityDescription {
        let entity = FEntityDescription()
        entity.name = type.entityName
        
        func attribute(from attr: FCDAttribute) -> NSAttributeDescription {
            let newAttr = NSAttributeDescription()
            newAttr.name = attr.name
            newAttr.attributeType = attr.type.cdAttrType
            newAttr.isOptional = attr.isOptional
            if attr.isIndexed {
                if #available(iOS 11.0, *) {
//                    TODO:

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
//
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
            switch rl.type {
            case .one:
                r.minCount = 0
                r.maxCount = 1
            case .many:
                r.minCount = 0
                r.maxCount = 0
            }
            r.isOptional = rl.isOptional
            return r
        }
        
        var props: Array<NSPropertyDescription> = type.entityAttributes.map { (attr) -> NSAttributeDescription in
            return attribute(from: attr)
        }
        
        if let rls = type.entityRelations,
            !rls.isEmpty {
            for rl in rls {
                props.append(relation(from: rl))
            }
        }
        
        entity.properties = props
        return entity
    }
}
