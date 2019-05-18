//
//  FCoreDataManager.swift
//  FCoreData
//
//  Created by Shohin Tagaev on 2/12/19.
//  Copyright © 2019 Shohin Tagaev. All rights reserved.
//

import UIKit
import CoreData

public enum FCoreDataMigrationType {
    case restore
}

final public class FCoreDataManager {
    // MARK: - Initialization
    private var configManagedModel: ((FManagedObjectModel) -> ())!
    
    private let folderPath: String
    private let modelName: String
    private let modelPath: String
    private let storeName: String
    private let storePath: String
    private let migrationType: FCoreDataMigrationType
    public init(modelName: String,
                migrationType: FCoreDataMigrationType) {
        self.modelName = modelName
        self.migrationType = migrationType
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths.first ?? ""
        
        let modelFile = "\(modelName).momd"
        
        let dbPath = "\(documentsDirectory)/db"
        
        self.folderPath = "\(dbPath)/model"
        
        self.modelPath = "\(self.folderPath)/\(modelFile)"
        print("Model path: \(self.modelPath)")
        
        self.storeName = "\(self.modelName).sqlite"
        self.storePath = "\(dbPath)/\(self.storeName)"
        print("Store path: \(self.storePath)")
    }
    
    public private(set) lazy var managedObjectContext: NSManagedObjectContext = {
        return self.newManagedObjectContext()
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        return self.newPersistentStoreCoordinator()
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        return self.objectModel() ?? self.newObjectModel()
    }()
    
    private var existsObjectModel: Bool {
        return FileManager.default.fileExists(atPath: self.modelPath)
    }
    
    private var existsFolder: Bool {
        return FileManager.default.fileExists(atPath: self.folderPath)
    }
    
    public func set(configManagedModel: @escaping ((FManagedObjectModel) -> ())) {
        self.configManagedModel = configManagedModel
    }
    
    @discardableResult
    public func delete() -> Bool {
        return self.tryDelete()
    }
    
    public func recreate() {
        self.tryDelete()
        self.create()
    }
    
    public func create() {
        self.managedObjectModel = self.newObjectModel()
        self.persistentStoreCoordinator = self.newPersistentStoreCoordinator()
        self.managedObjectContext = self.newManagedObjectContext()
    }
    
    public func migrate() {
        switch self.migrationType {
        case .restore:
            self.restoreMigration()
        }
    }
    
    private func restoreMigration() {
        self.recreate()
    }
    
    @discardableResult
    private func tryDelete() -> Bool {
        if self.existsFolder {
            do {
                try FileManager.default.removeItem(atPath: self.folderPath)
                self.deletePersistentStore()
                return true
            } catch {
                print(error)
                return false
            }
        }
        return false
    }
    
    private func deletePersistentStore() {
        if let persistentStore = self.persistentStoreCoordinator.persistentStores.last {
            let storeUrl = self.persistentStoreCoordinator.url(for: persistentStore)
            self.managedObjectContext.performAndWait {
                self.managedObjectContext.reset()
                do {
                    try self.persistentStoreCoordinator.remove(persistentStore)
                    try FileManager.default.removeItem(at: storeUrl)
                } catch {
                    print("Error removing Persistent store: \(error)")
                }
            }
        }
    }
    
    private func config(persistentStoreCoordinator: NSPersistentStoreCoordinator, url: URL) {
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do {
            // Add Persistent Store
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            
        } catch {
            fatalError("Unable to Add Persistent Store")
        }
    }
    
    private func objectModel() -> FManagedObjectModel? {
        if self.existsObjectModel {
            let modelUrl = URL(fileURLWithPath: self.modelPath)
            do {
                let data = try Data(contentsOf: modelUrl)
                let managedObjectModel: NSManagedObjectModel
                if #available(iOS 12.0, *) {
                    do {
                        guard let mom = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSManagedObjectModel.self, from: data) else {
                            fatalError("Unable to Load Data Model")
                        }
                        managedObjectModel = mom
                    } catch {
                        print("Error on loading managed object model. REASON:")
                        print(error)
                        fatalError("Error on loading managed object model.")
                    }
                } else {
                    guard let mom = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSManagedObjectModel else {
                        fatalError("Unable to Load Data Model")
                    }
                    
                    managedObjectModel = mom
                }
                
                return managedObjectModel
            } catch {
                print("Unable to Load Data. REASON:")
                print(error)
                fatalError("Unable to Load Data")
            }
        }
        
        return nil
    }
    
    private func newObjectModel() -> FManagedObjectModel {
        let objectModel = FManagedObjectModel()
        self.configManagedModel(objectModel)
        
        
        let modelData: Data
        if #available(iOS 12.0, *) {
            do {
                modelData = try NSKeyedArchiver.archivedData(withRootObject: objectModel, requiringSecureCoding: true)
            } catch {
                print("Error on archiving data. REASON:")
                print(error)
                fatalError("Error on archiving data.")
            }
        } else {
            modelData = NSKeyedArchiver.archivedData(withRootObject: objectModel)
        }
        
        do {
            do {
                try FileManager.default.createDirectory(atPath: self.folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error on creating db directory. REASON:")
                print(error)
                fatalError("Error on creating db directory.")
            }
            let modelUrl = URL(fileURLWithPath: self.modelPath)
            try modelData.write(to: modelUrl, options: Data.WritingOptions.atomic)
        } catch {
            print("Error on writing model data. REASON:")
            print(error)
            fatalError("Error on writing model data")
        }
        
        return objectModel
    }
    
    private func newPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        // Initialize Persistent Store Coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        // Helpers
        let fileManager = FileManager.default
        let storeName = self.storeName
        
        // URL Documents Directory
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // URL Persistent Store
        let persistentStoreURL = documentsDirectoryURL.appendingPathComponent(storeName)
        self.config(persistentStoreCoordinator: persistentStoreCoordinator, url: persistentStoreURL)
        
        return persistentStoreCoordinator
    }
    
    private func newManagedObjectContext() -> NSManagedObjectContext {
        // Initialize Managed Object Context
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // Configure Managed Object Context
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }
    
    // MARK: - Notification Handling
    
    @objc
    private func saveChanges(_ notification: Notification) {
        saveChanges()
    }
    
    // MARK: - Helper Methods
    
    private func setupNotificationHandling() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(saveChanges(_:)),
                                       name: UIApplication.willTerminateNotification,
                                       object: nil)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(saveChanges(_:)),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
    }
    
    // MARK: -
    
    private func saveChanges() {
        guard managedObjectContext.hasChanges else { return }
        
        do {
            try managedObjectContext.save()
        } catch {
            print("Unable to Save Managed Object Context")
            print("\(error), \(error.localizedDescription)")
        }
    }
}
