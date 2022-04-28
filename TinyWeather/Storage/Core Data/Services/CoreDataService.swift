//
//  CoreDataService.swift
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
import RxSwift

class CoreDataService {
    
    let store: CoreDataStoreProviding
    let container: NSPersistentContainer
    
    lazy var viewContext: NSManagedObjectContext = {
        return self.container.viewContext
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let ctx: NSManagedObjectContext = self.container.newBackgroundContext()
        ctx.automaticallyMergesChangesFromParent = true
        ctx.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return ctx
    }()
    
    init(store: CoreDataStoreProviding) {
        self.store = store
        self.container = self.store.setupContainer()
    }
    
}
