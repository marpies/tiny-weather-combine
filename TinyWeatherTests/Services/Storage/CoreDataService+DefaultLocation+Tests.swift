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
import Combine
import CoreData
import TWModels
@testable import TinyWeather

class CoreDataService_DefaultLocation_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: DefaultLocationStorageManaging!
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
    
    func testLoadDefaultLocation() throws {
        let expectNil = expectation(description: "default location should be nil")
        let expectNotNil = expectation(description: "default location should be nil")
        
        self.sut.defaultLocation
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail(error.localizedDescription)
                }
                
                let model: WeatherLocation = TestLocations.location1
                
                // Insert default location
                self.context.performAndWaitWith { ctx in
                    CoreDataTestModels.createLocation(model, isDefault: true, isFavorite: false, context: ctx)
                }
                
                self.sut.defaultLocation
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            XCTFail(error.localizedDescription)
                        }
                    }, receiveValue: { location in
                        XCTAssertNotNil(location)
                        
                        XCTAssertEqual(location!.name, model.name)
                        XCTAssertEqual(location!.country, model.country)
                        XCTAssertEqual(location!.state, model.state)
                        XCTAssertEqual(location!.lat, model.lat, accuracy: 0.0001)
                        XCTAssertEqual(location!.lon, model.lon, accuracy: 0.0001)
                        
                        expectNotNil.fulfill()
                    })
                    .store(in: &self.cancellables)
            }, receiveValue: { location in
                XCTAssertNil(location)
                
                expectNil.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func testSaveDefaultLocation() throws {
        let model1: WeatherLocation = TestLocations.location1
        
        let expectSave = expectation(description: "save did not succeed")
        let expectOverwrite = expectation(description: "expected default location to be overwritten")
        
        self.sut.saveDefaultLocation(model1)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectSave.fulfill()
                    
                case .failure(let error):
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
                
                self.sut.saveDefaultLocation(model2)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            expectOverwrite.fulfill()
                            
                        case .failure(let error):
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
                    }, receiveValue: { })
                    .store(in: &self.cancellables)
            }, receiveValue: { })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
}
