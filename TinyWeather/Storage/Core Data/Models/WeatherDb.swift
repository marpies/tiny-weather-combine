//
//  WeatherDb.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import CoreData

class WeatherDb: NSManagedObject {
    
    enum Attributes {
        static let entityName: String = "WeatherDb"
    }
    
    struct Model {
        let location: LocationDb.Model
        let condition: Int
        let conditionDescription: String
        let lastUpdate: Date
        let timezoneOffset: Double
        let sunrise: Date
        let sunset: Date
        let windSpeed: Float
        let rainAmount: Float
        let snowAmount: Float
        let temperature: Float
        let isNight: Bool
        let daily: [DailyWeatherDb.Model]
    }
    
    @NSManaged var location: LocationDb
    @NSManaged var condition: Int
    @NSManaged var conditionDescription: String
    @NSManaged var lastUpdate: Date
    @NSManaged var timezoneOffset: Double
    @NSManaged var sunrise: Date
    @NSManaged var sunset: Date
    @NSManaged var windSpeed: Float
    @NSManaged var rainAmount: Float
    @NSManaged var snowAmount: Float
    @NSManaged var temperature: Float
    @NSManaged var isNight: Bool
    @NSManaged var daily: NSSet
    
    var model: WeatherDb.Model {
        let set: Set<DailyWeatherDb>? = self.mutableSetValue(forKeyPath: #keyPath(WeatherDb.daily)) as? Set<DailyWeatherDb>
        let daily: [DailyWeatherDb.Model] = set?.map({ $0.model }).sorted(by: { $0.date < $1.date }) ?? []
        return WeatherDb.Model(location: location.model, condition: condition, conditionDescription: conditionDescription, lastUpdate: lastUpdate, timezoneOffset: timezoneOffset, sunrise: sunrise, sunset: sunset, windSpeed: windSpeed, rainAmount: rainAmount, snowAmount: snowAmount, temperature: temperature, isNight: isNight, daily: daily)
    }
    
}
