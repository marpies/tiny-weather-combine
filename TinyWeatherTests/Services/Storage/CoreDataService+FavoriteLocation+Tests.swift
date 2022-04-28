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
import RxSwift
import RxBlocking
import CoreData
import TWModels
@testable import TinyWeather

class CoreDataService_FavoriteLocation_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: FavoriteLocationStorageManaging!
    
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        self.sut = try self.setupPersistentCoreData()
    }
    
    override func tearDownWithError() throws {
        self.sut = nil
        self.context = nil
    }

    func testFavoriteStatusNonExistentLocation() throws {
        let location: WeatherLocation = TestLocations.location1
        
        let nonExistent = try self.sut.loadLocationFavoriteStatus(location)
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertFalse(nonExistent)
    }
    
    func testLoadFavoriteStatusForLocation() throws {
        let location1: WeatherLocation = TestLocations.location1
        
        let nonExistent = try self.sut.loadLocationFavoriteStatus(location1)
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertFalse(nonExistent)
        
        CoreDataTestModels.createLocation(location1, isDefault: false, isFavorite: true, context: self.context)
        
        let location1Status = try self.sut.loadLocationFavoriteStatus(location1)
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertTrue(location1Status)
        
        let location2: WeatherLocation = TestLocations.location2
        
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: false, context: self.context)
        
        let location2Status = try self.sut.loadLocationFavoriteStatus(location2)
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertFalse(location2Status)
    }
    
    func testLoadFavoriteLocations() throws {
        let noLocations = try self.sut.loadFavoriteLocations()
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertTrue(noLocations.isEmpty)
        
        let location1: WeatherLocation = TestLocations.location1
        let location2: WeatherLocation = TestLocations.location2
        
        CoreDataTestModels.createLocation(location1, isDefault: false, isFavorite: true, context: self.context)
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: true, context: self.context)
        CoreDataTestModels.createLocation(location2, isDefault: false, isFavorite: false, context: self.context)
        
        let locations = try self.sut.loadFavoriteLocations()
            .toBlocking(timeout: 1)
            .single()
        
        XCTAssertEqual(locations.count, 2)
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
        
        let isFavorite = try self.sut.saveLocationFavoriteStatus(location, isFavorite: true).toBlocking(timeout: 1).single()
        
        XCTAssertTrue(isFavorite)
        
        self.context.performAndWaitWith { ctx in
            do {
                let results: [LocationDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                XCTAssertTrue(results[0].isFavorite)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        let isNotFavorite = try self.sut.saveLocationFavoriteStatus(location, isFavorite: false).toBlocking(timeout: 1).single()
        
        XCTAssertFalse(isNotFavorite)
        
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
