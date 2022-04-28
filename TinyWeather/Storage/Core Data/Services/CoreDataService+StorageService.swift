//
//  CoreDataService+StorageService.swift
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
import TWExtensions

extension CoreDataService: StorageService {
    
    var initialize: Completable {
        return Completable.create { observer in
            self.container.loadPersistentStores { (persistentStoreDescription, error) in
                if let e = error {
                    observer(.error(e))
                } else {
                    self.container.viewContext.automaticallyMergesChangesFromParent = true
                    self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    
                    if case .sql(let url) = self.store.type {
                        var fileUrl: URL = url
                        fileUrl.excludeFromBackup()
                    }
                    
                    observer(.completed)
                }
            }
            
            return Disposables.create()
        }
    }
    
}
