//
//  LocationTestModels.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import TWModels

fileprivate struct TestWeatherLocation: WeatherLocation {
    let name: String
    let state: String?
    let country: String
    let lon: Double
    let lat: Double
}

enum TestLocations {
    static let location1: WeatherLocation = TestWeatherLocation(name: "TestName", state: "TestState", country: "TestCountry", lon: 10, lat: 20)
    static let location2: WeatherLocation = TestWeatherLocation(name: "TestName2", state: "TestState2", country: "TestCountry2", lon: 10.1, lat: 20.1)
}
