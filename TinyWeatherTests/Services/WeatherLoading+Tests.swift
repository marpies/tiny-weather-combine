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
import Combine
@testable import TinyWeather

class WeatherLoading_Tests: XCTestCase {
    
    private var sut: WeatherLoading!
    private var storage: LocationWeatherStorageTestMock!
    private var api: RequestExecutingCurrentAndDaily!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.storage = LocationWeatherStorageTestMock()
        self.api = RequestExecutingCurrentAndDaily()
        self.cancellables = []
        
        self.sut = WeatherLoadingService(storage: self.storage, apiService: self.api)
    }

    override func tearDownWithError() throws {
        self.sut = nil
        self.cancellables.removeAll()
    }

    func test_no_api_request_is_made_when_cache_is_recent() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate = Date().timeIntervalSince1970
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        let expectNoApiCalls = expectation(description: "expected no api calls")
        let expectedCachedResponse = expectation(description: "expected cached response")
        
        self.sut.loadWeather(latitude: 0, longitude: 0)
            .sink(receiveCompletion: { completion in
                if self.api.numExecuteCalls == 0 {
                    expectNoApiCalls.fulfill()
                }
            }, receiveValue: { response in
                XCTAssertEqual(response.current.lastUpdate, lastUpdate, accuracy: 0.0001)
                expectedCachedResponse.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_api_request_is_made_when_cache_is_not_recent() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate: TimeInterval = 1
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let expectApiCall = expectation(description: "expected api call to be made")
        let expectedApiResponse = expectation(description: "expected api response")
        
        self.sut.loadWeather(latitude: 0, longitude: 0)
            .sink(receiveCompletion: { completion in
                if self.api.numExecuteCalls == 1 {
                    expectApiCall.fulfill()
                }
            }, receiveValue: { response in
                XCTAssertEqual(response.current.lastUpdate, self.api.requestTimestamp, accuracy: 0.0001)
                expectedApiResponse.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_api_request_is_made_when_cache_fails() throws {
        self.storage.cacheDuration = 10 * 60
        self.storage.shouldFail = true
        
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let expectApiCall = expectation(description: "expected api call to be made")
        let expectedApiResponse = expectation(description: "expected api response")
        
        self.sut.loadWeather(latitude: 0, longitude: 0)
            .sink(receiveCompletion: { completion in
                if self.api.numExecuteCalls == 1 {
                    expectApiCall.fulfill()
                }
            }, receiveValue: { response in
                XCTAssertEqual(response.current.lastUpdate, self.api.requestTimestamp, accuracy: 0.0001)
                expectedApiResponse.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_error_is_returned_when_cache_is_outdated_and_api_request_fails() throws {
        self.storage.cacheDuration = 10 * 60
        
        let lastUpdate: TimeInterval = 1
        let current = TestWeather.getCurrentWeather(lastUpdate: lastUpdate)
        let daily = TestWeather.getCurrentDailyWeather(timeStart: lastUpdate)
        
        self.storage.weather = Weather.Overview.Response(timezoneOffset: 0, current: current, daily: daily)
        
        self.api.shouldFail = true
        self.api.requestTimestamp = Date().timeIntervalSince1970
        
        let expectApiCall = expectation(description: "expected api call to be made")
        let expectedError = expectation(description: "expected error")
        
        self.sut.loadWeather(latitude: 0, longitude: 0)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectedError.fulfill()
                }
                
                if self.api.numExecuteCalls == 1 {
                    expectApiCall.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("should not receive value")
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
}
