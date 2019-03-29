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
    
    private let modelName: String
    public init(modelName: String) {
        self.modelName = modelName
    }
    
    public func set(configManagedModel: @escaping ((FManagedObjectModel) -> ())) {
        self.configManagedModel = configManagedModel
    }
    
    public private(set) lazy var managedObjectContext: NSManagedObjectContext = {
        // Initialize Managed Object Context
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // Configure Managed Object Context
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths.first ?? ""
        let modelFile = "\(self.modelName).momd"
        let dbPath = "\(documentsDirectory)/db"
        let modelPath = "\(dbPath)/\(modelFile)"
        
        print("Model path: \(modelPath)")
        
        if FileManager.default.fileExists(atPath: modelPath) {
            let modelUrl = URL(fileURLWithPath: modelPath)
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
        
//        // Fetch Model URL
//        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd") else {
//            fatalError("Unable to Find Data Model")
//        }
//
//        // Initialize Managed Object Model
//        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
//            fatalError("Unable to Load Data Model")
//        }
//
//        return managedObjectModel
        
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
                let dbUrl = URL(fileURLWithPath: dbPath, isDirectory: true)
                try FileManager.default.createDirectory(at: dbUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error on creating db directory. REASON:")
                print(error)
                fatalError("Error on creating db directory.")
            }
            let modelUrl = URL(fileURLWithPath: modelPath)
            try modelData.write(to: modelUrl, options: Data.WritingOptions.atomic)
        } catch {
            print("Error on writing model data. REASON:")
            print(error)
            fatalError("Error on writing model data")
        }
        
        return objectModel
        
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Initialize Persistent Store Coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        // Helpers
        let fileManager = FileManager.default
        let storeName = "\(self.modelName).sqlite"
        
        // URL Documents Directory
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // URL Persistent Store
        let persistentStoreURL = documentsDirectoryURL.appendingPathComponent(storeName)
        
        do {
            // Add Persistent Store
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: nil)
            
        } catch {
            fatalError("Unable to Add Persistent Store")
        }
        
        return persistentStoreCoordinator
    }()
    
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
