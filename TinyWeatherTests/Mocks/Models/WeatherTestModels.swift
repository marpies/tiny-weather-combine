//
//  WeatherTestModels.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
@testable import TinyWeather

enum TestWeather {
    static let current = Weather.Overview.Response(timezoneOffset: 0, current: TestWeather.getCurrentWeather(), daily: TestWeather.getCurrentDailyWeather())
    static let updated = Weather.Overview.Response(timezoneOffset: 0, current: TestWeather.updatedWeather, daily: TestWeather.updatedDailyWeather)
    
    static func getCurrentWeather(lastUpdate: TimeInterval = 10) -> Weather.Current.Response {
        let info = Weather.Info.Response(id: 501, description: "Rainy", isNight: false)
        return Weather.Current.Response(weather: info, lastUpdate: lastUpdate, sunrise: 123, sunset: 456, temperature: 10, windSpeed: 5, rain: 1, snow: 0)
    }
    
    private static var updatedWeather: Weather.Current.Response {
        let info = Weather.Info.Response(id: 800, description: "Clear sky", isNight: false)
        return Weather.Current.Response(weather: info, lastUpdate: 60 * 60, sunrise: 200, sunset: 600, temperature: 23, windSpeed: 2, rain: 0, snow: 0)
    }
    
    static func getCurrentDailyWeather(timeStart: TimeInterval = 10) -> [Weather.Day.Response] {
        (1...7).map { i in
            let date: TimeInterval = (TimeInterval(i) * 24 * 60 * 60) + timeStart
            let info = Weather.Info.Response(id: 501, description: "Rainy", isNight: false)
            return Weather.Day.Response(date: date, weather: info, tempMin: -5, tempMax: 10, rain: 2, snow: 0, windSpeed: 5)
        }
    }
    
    private static var updatedDailyWeather: [Weather.Day.Response] {
        (1...7).map { i in
            let date: TimeInterval = TimeInterval(i) * 24 * 60 * 60
            let info = Weather.Info.Response(id: 800, description: "Clear sky", isNight: false)
            return Weather.Day.Response(date: date, weather: info, tempMin: 3, tempMax: 20, rain: 0, snow: 0, windSpeed: 2)
        }
    }
}
