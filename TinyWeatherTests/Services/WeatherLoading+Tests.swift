//
//  WeatherLoading+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
@testable import TinyWeather

class WeatherLoading_Tests: XCTestCase {
    
    private var sut: WeatherLoading!
    private var storage: LocationWeatherStorageTestMock!
    private var api: RequestExecutingCurrentAndDaily!

    override func setUpWithError() throws {
        self.storage = LocationWeatherStorageTestMock()
        self.api = RequestExecutingCurrentAndDaily()
        
        self.sut = WeatherLoadingService(storage: self.storage, apiService: self.api)
    }

    override func tearDownWithError() throws {
        self.sut = nil
    }

    func test_no_api_request_is_made_when_cache_is_recent() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate = Date().timeIntervalSince1970
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        let response: Weather.Overview.Response = try self.sut.loadWeather(latitude: 0, longitude: 0).toBlocking(timeout: 1).single()
        
        XCTAssertEqual(self.api.numExecuteCalls, 0)
        
        XCTAssertEqual(response.current.lastUpdate, lastUpdate, accuracy: 0.0001)
    }
    
    func test_api_request_is_made_when_cache_is_not_recent() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate: TimeInterval = 1
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let response: Weather.Overview.Response = try self.sut.loadWeather(latitude: 0, longitude: 0).toBlocking(timeout: 1).single()
        
        XCTAssertEqual(self.api.numExecuteCalls, 1)
        
        XCTAssertEqual(response.current.lastUpdate, self.api.requestTimestamp, accuracy: 0.0001)
    }
    
    func test_api_request_is_made_when_cache_fails() throws {
        self.storage.cacheDuration = 10 * 60
        self.storage.shouldFail = true
        
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let response: Weather.Overview.Response = try self.sut.loadWeather(latitude: 0, longitude: 0).toBlocking(timeout: 1).single()
        
        XCTAssertEqual(self.api.numExecuteCalls, 1)
        
        XCTAssertEqual(response.current.lastUpdate, self.api.requestTimestamp, accuracy: 0.0001)
    }
    
    func test_error_is_returned_when_cache_is_outdated_and_api_request_fails() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate: TimeInterval = 1
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        self.api.shouldFail = true
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let response = self.sut.loadWeather(latitude: 0, longitude: 0).toBlocking(timeout: 1).materialize()
        
        switch response {
        case .completed(_):
            XCTFail("should not complete")
            
        case .failed(_, _):
            break
        }
        
        XCTAssertEqual(self.api.numExecuteCalls, 1)
    }
    
}
