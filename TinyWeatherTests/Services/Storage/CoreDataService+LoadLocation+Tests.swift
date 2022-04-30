//
//  CoreDataService+LoadLocation+Tests.swift
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
import TWModels
@testable import TinyWeather

class CoreDataService_LoadLocation_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: CoreDataService!
    
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        self.sut = try self.setupInMemoryCoreData()
    }

    override func tearDownWithError() throws {
        self.sut = nil
        self.context = nil
    }

    func testLoadLocation() throws {
        let location1 = try self.sut.loadLocation(latitude: 10, longitude: 20, context: self.context)
        
        XCTAssertNil(location1)
        
        let model1: WeatherLocation = TestLocations.location1
        let model2: WeatherLocation = TestLocations.location2
        
        self.context.performAndWaitWith { ctx in
            CoreDataTestModels.createLocation(model1, isDefault: false, isFavorite: false, context: ctx)
            CoreDataTestModels.createLocation(model2, isDefault: false, isFavorite: false, context: ctx)
        }
        
        let location2 = try XCTUnwrap(try self.sut.loadLocation(latitude: model1.lat, longitude: model1.lon, context: self.context))
        
        XCTAssertEqual(location2.name, model1.name)
        XCTAssertEqual(location2.country, model1.country)
        XCTAssertEqual(location2.state, model1.state)
        XCTAssertEqual(location2.lat, model1.lat, accuracy: 0.0001)
        XCTAssertEqual(location2.lon, model1.lon, accuracy: 0.0001)
        
        let location3 = try XCTUnwrap(try self.sut.loadLocation(latitude: model2.lat, longitude: model2.lon, context: self.context))
        
        XCTAssertEqual(location3.name, model2.name)
        XCTAssertEqual(location3.country, model2.country)
        XCTAssertEqual(location3.state, model2.state)
        XCTAssertEqual(location3.lat, model2.lat, accuracy: 0.0001)
        XCTAssertEqual(location3.lon, model2.lon, accuracy: 0.0001)
    }

}
