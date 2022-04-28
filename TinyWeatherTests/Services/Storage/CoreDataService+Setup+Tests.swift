//
//  CoreDataService+Setup+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
import CoreData
@testable import TinyWeather

protocol CoreDataTestingSetup: AnyObject {
    var context: NSManagedObjectContext! { get set }
    
    func setupPersistentCoreData() throws -> CoreDataService
    func setupInMemoryCoreData() throws -> CoreDataService
}

extension CoreDataTestingSetup where Self: XCTestCase {
    
    func setupPersistentCoreData() throws -> CoreDataService {
        let store = CoreDataStore(inMemory: false)
        let service = CoreDataService(store: store)
        
        let expect = expectation(description: #function)
        
        switch store.type {
        case .sql(let file):
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
            
        case .inMemory:
            XCTFail("invalid store type")
        }
        
        service.container.loadPersistentStores { _, error in
            XCTAssertNil(error)
            
            self.context = service.backgroundContext
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        return service
    }
    
    func setupInMemoryCoreData() throws -> CoreDataService {
        let store = CoreDataStore(inMemory: true)
        let service = CoreDataService(store: store)
        
        let expect = expectation(description: #function)
        
        switch store.type {
        case .sql(_):
            XCTFail("invalid store type")
            
        case .inMemory:
            break
        }
        
        service.container.loadPersistentStores { _, error in
            XCTAssertNil(error)
            
            self.context = service.backgroundContext
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        return service
    }
    
}
