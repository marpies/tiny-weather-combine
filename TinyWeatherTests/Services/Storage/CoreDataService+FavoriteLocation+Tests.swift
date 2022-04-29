//
//  CoreDataService+FavoriteLocation+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
import Combine
import CoreData
import TWModels
@testable import TinyWeather

class CoreDataService_FavoriteLocation_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: FavoriteLocationStorageManaging!
    private var cancellables: Set<AnyCancellable>!
    
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        self.sut = try self.setupPersistentCoreData()
        self.cancellables = []
    }
    
    override func tearDownWithError() throws {
        self.sut = nil
        self.context = nil
        self.cancellables.removeAll()
    }

    func testFavoriteStatusNonExistentLocation() throws {
        let location: WeatherLocation = TestLocations.location1
        
        let result = try awaitPublisher(self.sut.loadLocationFavoriteStatus(location))
        
        XCTAssertFalse(try result.get())
    }
    
    func testLoadFavoriteStatusForLocation() throws {
        let location1: WeatherLocation = TestLocations.location1
        
        let nonexistent = try awaitPublisher(self.sut.loadLocationFavoriteStatus(location1)).get()
        
        XCTAssertFalse(nonexistent)
        
        CoreDataTestModels.createLocation(location1, isDefault: false, isFavorite: true, context: self.context)
        
        let existent = try awaitPublisher(self.sut.loadLocationFavoriteStatus(location1)).get()
        
        XCTAssertTrue(existent)
        
        let location2: WeatherLocation = TestLocations.location2
        
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: false, context: self.context)
        
        let nonexistent2 = try awaitPublisher(self.sut.loadLocationFavoriteStatus(location2)).get()
        
        XCTAssertFalse(nonexistent2)
    }
    
    func testLoadFavoriteLocations() throws {
        let location1: WeatherLocation = TestLocations.location1
        let location2: WeatherLocation = TestLocations.location2
        
        let initialLocations = try awaitPublisher(self.sut.loadFavoriteLocations()).get()
        
        XCTAssertTrue(initialLocations.isEmpty)
        
        CoreDataTestModels.createLocation(location1, isDefault: false, isFavorite: true, context: self.context)
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: true, context: self.context)
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: false, context: self.context)
        
        let newLocations = try awaitPublisher(self.sut.loadFavoriteLocations()).get()
        
        XCTAssertEqual(newLocations.count, 2)
    }
    
    func testSaveFavoriteStatusForLocation() throws {
        let location: WeatherLocation = TestLocations.location1
        
        let e: Double = 0.0001
        let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
        request.predicate = NSPredicate(format: "(lat > %lf AND lat < %lf) AND (lon > %lf AND lon < %lf)", location.lat - e, location.lat + e, location.lon - e, location.lon + e)
        
        self.context.performAndWaitWith { ctx in
            CoreDataTestModels.createLocation(location, isDefault: false, isFavorite: false, context: ctx)
            
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                XCTAssertFalse(results[0].isFavorite)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        let makeFavorite = try awaitPublisher(self.sut.saveLocationFavoriteStatus(location, isFavorite: true)).get()
        
        XCTAssertTrue(makeFavorite)
        
        self.context.performAndWaitWith { ctx in
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                XCTAssertTrue(results[0].isFavorite)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        let makeNotFavorite = try awaitPublisher(self.sut.saveLocationFavoriteStatus(location, isFavorite: false)).get()
        
        XCTAssertFalse(makeNotFavorite)
        
        self.context.performAndWaitWith { ctx in
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                XCTAssertFalse(results[0].isFavorite)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

}
