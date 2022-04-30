//
//  CoreDataService+LocationWeather+Tests.swift
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
import Combine
@testable import TinyWeather

class CoreDataService_LocationWeather_Tests: XCTestCase, CoreDataTestingSetup {
    
    private var sut: LocationWeatherStorageManaging!
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

    func testSavingLocationWeather() throws {
        let location: WeatherLocation = TestLocations.location1
        let weather1 = TestWeather.current
        
        self.context.performAndWaitWith { ctx in
            let e: Double = 0.0001
            let request = NSFetchRequest<WeatherDb>(entityName: WeatherDb.Attributes.entityName)
            request.predicate = NSPredicate(format: "(location.lat > %lf AND location.lat < %lf) AND (location.lon > %lf AND location.lon < %lf)", location.lat - e, location.lat + e, location.lon - e, location.lon + e)
            
            do {
                let results: [WeatherDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 0)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        // Save initial weather
        try self.saveAndVerifyWeather(weather1, location: location)
        
        // Update weather
        let weather2 = TestWeather.updated
        try self.saveAndVerifyWeather(weather2, location: location)
    }
    
    func testLoadingLocationWeather() throws {
        let location: WeatherLocation = TestLocations.location1
        let weather = TestWeather.current
        
        let response = try awaitPublisher(self.sut.loadLocationWeather(latitude: location.lat, longitude: location.lon)).get()
        
        XCTAssertNil(response)
        
        self.context.performAndWaitWith { ctx in
            CoreDataTestModels.createWeather(location: location, weather: weather, context: ctx)
        }
        
        let loadedWeather = try awaitPublisher(self.sut.loadLocationWeather(latitude: location.lat, longitude: location.lon)).get()
        
        XCTAssertNotNil(loadedWeather)
        
        XCTAssertEqual(loadedWeather!.current.weather.id, weather.current.weather.id)
        XCTAssertEqual(loadedWeather!.current.weather.description, weather.current.weather.description)
        XCTAssertEqual(loadedWeather!.current.weather.isNight, weather.current.weather.isNight)
        XCTAssertEqual(loadedWeather!.current.lastUpdate, weather.current.lastUpdate, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.timezoneOffset, weather.timezoneOffset, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.sunrise, weather.current.sunrise, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.sunset, weather.current.sunset, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.windSpeed, weather.current.windSpeed, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.rain, weather.current.rain, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.snow, weather.current.snow, accuracy: 0.001)
        XCTAssertEqual(loadedWeather!.current.temperature, weather.current.temperature, accuracy: 0.001)
        
        XCTAssertEqual(loadedWeather!.daily.count, weather.daily.count)
        XCTAssertGreaterThan(loadedWeather!.daily.count, 0)
        
        for i in 0..<weather.daily.count - 1 {
            let other = loadedWeather!.daily[i]
            let model = weather.daily[i]
            
            XCTAssertEqual(other.date, model.date, accuracy: 0.001)
            XCTAssertEqual(other.weather.id, model.weather.id)
            XCTAssertEqual(other.windSpeed, model.windSpeed, accuracy: 0.001)
            XCTAssertEqual(other.rain, model.rain, accuracy: 0.001)
            XCTAssertEqual(other.snow, model.snow, accuracy: 0.001)
            XCTAssertEqual(other.tempMin, model.tempMin, accuracy: 0.001)
            XCTAssertEqual(other.tempMax, model.tempMax, accuracy: 0.001)
            
            // Date must be earlier than that of the next daily model
            let next = loadedWeather!.daily[i + 1]
            XCTAssertLessThan(other.date, next.date)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func saveAndVerifyWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) throws {
        let _ = try awaitPublisher(self.sut.saveLocationWeather(weather, location: location))
        
        self.context.performAndWaitWith { ctx in
            let e: Double = 0.0001
            let request = NSFetchRequest<WeatherDb>(entityName: WeatherDb.Attributes.entityName)
            request.predicate = NSPredicate(format: "(location.lat > %lf AND location.lat < %lf) AND (location.lon > %lf AND location.lon < %lf)", location.lat - e, location.lat + e, location.lon - e, location.lon + e)
            
            do {
                let results: [WeatherDb] = try ctx.fetch(request)
                
                XCTAssertEqual(results.count, 1)
                
                let loadedWeather: WeatherDb = results[0]
                
                let currentWeather = weather.current
                XCTAssertEqual(loadedWeather.condition, currentWeather.weather.id)
                XCTAssertEqual(loadedWeather.conditionDescription, currentWeather.weather.description)
                XCTAssertEqual(loadedWeather.isNight, currentWeather.weather.isNight)
                XCTAssertEqual(loadedWeather.lastUpdate.timeIntervalSince1970, currentWeather.lastUpdate, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.timezoneOffset, weather.timezoneOffset, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.sunrise.timeIntervalSince1970, currentWeather.sunrise, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.sunset.timeIntervalSince1970, currentWeather.sunset, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.windSpeed, currentWeather.windSpeed, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.rainAmount, currentWeather.rain, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.snowAmount, currentWeather.snow, accuracy: 0.001)
                XCTAssertEqual(loadedWeather.temperature, currentWeather.temperature, accuracy: 0.001)
                
                let dailySet: Set<DailyWeatherDb> = try XCTUnwrap(loadedWeather.daily as? Set<DailyWeatherDb>)
                let daily: [DailyWeatherDb] = dailySet.sorted(by: { $0.date < $1.date })
                
                XCTAssertEqual(daily.count, weather.daily.count)
                
                for (index, model) in weather.daily.enumerated() {
                    let other: DailyWeatherDb = daily[index]
                    
                    XCTAssertEqual(other.date.timeIntervalSince1970, model.date, accuracy: 0.001)
                    XCTAssertEqual(other.condition, model.weather.id)
                    XCTAssertEqual(other.windSpeed, model.windSpeed, accuracy: 0.001)
                    XCTAssertEqual(other.rainAmount, model.rain, accuracy: 0.001)
                    XCTAssertEqual(other.snowAmount, model.snow, accuracy: 0.001)
                    XCTAssertEqual(other.minTemperature, model.tempMin, accuracy: 0.001)
                    XCTAssertEqual(other.maxTemperature, model.tempMax, accuracy: 0.001)
                }
                
                // Should have X number of DailyWeatherDb instance stored, old daily weather should be deleted
                let request2 = NSFetchRequest<DailyWeatherDb>(entityName: DailyWeatherDb.Attributes.entityName)
                let results2: [DailyWeatherDb] = try ctx.fetch(request2)
                
                XCTAssertEqual(results2.count, weather.daily.count)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
}
