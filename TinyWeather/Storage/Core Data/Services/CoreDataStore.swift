//
//  CoreDataStore.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import CoreData

enum CoreDataStoreType {
    /// SQL store type along with the URL to the store file
    case sql(URL)
    
    /// In-memory store type
    case inMemory
}

protocol CoreDataStoreProviding {
    var name: String { get }
    var type: CoreDataStoreType { get }
    
    func setupContainer() -> NSPersistentContainer
}

struct CoreDataStore: CoreDataStoreProviding {
    
    let name: String = "TinyWeather.sqlite"
    let type: CoreDataStoreType
    
    init(inMemory: Bool) {
        if inMemory {
            self.type = .inMemory
        } else {
            var url: URL = NSPersistentContainer.defaultDirectoryURL()
            
            // Create the directory hierarchy if needed
            if !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error creating data store: \(error)")
                    
                    // Will be handled and informed about later when loading the persistent store
                }
            }
            
            url = url.appendingPathComponent(self.name)
            
            self.type = .sql(url)
        }
    }
    
    private var managedObjectModel: NSManagedObjectModel {
        let modelURL = Bundle.main.url(forResource: "TinyWeather", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }
    
    //
    // MARK: - Public
    //
    
    func setupContainer() -> NSPersistentContainer {
        let container: NSPersistentContainer = NSPersistentContainer(name: self.name, managedObjectModel: self.managedObjectModel)
        
        let description: NSPersistentStoreDescription
        
        switch self.type {
        case .sql(let url):
            description = NSPersistentStoreDescription(url: url)
            
        case .inMemory:
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        }
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [description]
        
        return container
    }
    
}
