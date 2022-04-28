//
//  WeatherModelTests.swift
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

class WeatherModelTests: XCTestCase {

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }

    func testDecodable() throws {
        let response = ResponseCurrentAndDaily.getSuccessResponse(timestamp: 123)
        
        let model = try JSONDecoder().decode(Weather.Overview.Response.self, from: response.asData)
        
        XCTAssertEqual(model.timezoneOffset, 36000, accuracy: 0.0001)
        
        XCTAssertEqual(model.current.lastUpdate, 123, accuracy: 0.0001)
        XCTAssertEqual(model.current.sunrise, 1649189483, accuracy: 0.0001)
        XCTAssertEqual(model.current.sunset, 1649231143, accuracy: 0.0001)
        XCTAssertEqual(model.current.temperature, 17.04, accuracy: 0.0001)
        XCTAssertEqual(model.current.windSpeed, 1.18 * 3.6, accuracy: 0.0001) // km/h
        XCTAssertEqual(model.current.rain, 0)
        XCTAssertEqual(model.current.snow, 0)
        XCTAssertEqual(model.current.weather.id, 804)
        XCTAssertEqual(model.current.weather.description, "overcast clouds")
        XCTAssertEqual(model.current.weather.isNight, true)
        
        let dailyResponse: [[String: Any]] = response["daily"] as! [[String: Any]]
        
        XCTAssertFalse(model.daily.isEmpty)
        XCTAssertEqual(model.daily.count, dailyResponse.count)
        
        for (model, response) in zip(model.daily, dailyResponse) {
            XCTAssertEqual(model.date, Double(response.int("dt")), accuracy: 0.0001)
            
            let temps: [String: Any] = response["temp"] as! [String: Any]
            XCTAssertEqual(model.tempMin, Float(temps.double("min")), accuracy: 0.0001)
            XCTAssertEqual(model.tempMax, Float(temps.double("max")), accuracy: 0.0001)
            XCTAssertEqual(model.windSpeed, Float(response.double("wind_speed")) * 3.6, accuracy: 0.0001) // km/h
            XCTAssertEqual(model.rain, Float(response.double("rain").rounded()), accuracy: 0.0001)
            
            let weathers: [[String: Any]] = response["weather"] as! [[String: Any]]
            let weather: [String: Any] = weathers[0]
            
            XCTAssertEqual(model.weather.id, weather["id"] as! Int)
            XCTAssertFalse(model.weather.isNight)
        }
    }

}
