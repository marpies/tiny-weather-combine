//
//  CoreDataService+DefaultLocation+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
import RxSwift
import RxBlocking
import CoreData
import TWModels
@testable import TinyWeather

class CoreDataService_DefaultLocation_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: DefaultLocationStorageManaging!
    
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        self.sut = try self.setupPersistentCoreData()
    }
    
    override func tearDownWithError() throws {
        self.sut = nil
        self.context = nil
    }
    
    func testLoadDefaultLocation() throws {
        let first = try self.sut.defaultLocation.toBlocking(timeout: 1).first()
        
        XCTAssertNil(first)
        
        let model: WeatherLocation = TestLocations.location1
        
        // Insert default location
        self.context.performAndWaitWith { ctx in
            CoreDataTestModels.createLocation(model, isDefault: true, isFavorite: false, context: ctx)
        }
        
        let second = try XCTUnwrap(try self.sut.defaultLocation.toBlocking(timeout: 1).first())
        
        XCTAssertEqual(second.name, model.name)
        XCTAssertEqual(second.country, model.country)
        XCTAssertEqual(second.state, model.state)
        XCTAssertEqual(second.lat, model.lat, accuracy: 0.0001)
        XCTAssertEqual(second.lon, model.lon, accuracy: 0.0001)
    }
    
    func testSaveDefaultLocation() throws {
        let model1: WeatherLocation = TestLocations.location1
        
        let save1 = self.sut.saveDefaultLocation(model1).toBlocking(timeout: 1).materialize()
        
        switch save1 {
        case .completed(_):
            break
            
        case .failed(_, let error):
            XCTFail(error.localizedDescription)
        }
        
        // Check default location
        self.context.performAndWaitWith { ctx in
            let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
            request.predicate = NSPredicate(format: "isDefault == true")
            
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                
                let loc = results[0]
                
                XCTAssertEqual(loc.name, model1.name)
                XCTAssertEqual(loc.country, model1.country)
                XCTAssertEqual(loc.state, model1.state)
                XCTAssertEqual(loc.lon, model1.lon)
                XCTAssertEqual(loc.lat, model1.lat)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        // Overwrite default location with a new one
        let model2: WeatherLocation = TestLocations.location2
        
        let save2 = self.sut.saveDefaultLocation(model2).toBlocking(timeout: 1).materialize()
        
        switch save2 {
        case .completed(_):
            break
            
        case .failed(_, let error):
            XCTFail(error.localizedDescription)
        }
        
        // Check default location again
        self.context.performAndWaitWith { ctx in
            let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
            request.predicate = NSPredicate(format: "isDefault == true")
            
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                
                let loc = results[0]
                
                XCTAssertEqual(loc.name, model2.name)
                XCTAssertEqual(loc.country, model2.country)
                XCTAssertEqual(loc.state, model2.state)
                XCTAssertEqual(loc.lon, model2.lon)
                XCTAssertEqual(loc.lat, model2.lat)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
}
