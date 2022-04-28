//
//  DailyWeatherDb.swift
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

class DailyWeatherDb: NSManagedObject {
    
    enum Attributes {
        static let entityName: String = "DailyWeatherDb"
    }
    
    struct Model {
        let date: Date
        let condition: Int
        let windSpeed: Float
        let rainAmount: Float
        let snowAmount: Float
        let minTemperature: Float
        let maxTemperature: Float
        let location: WeatherDb.Model
    }
    
    @NSManaged var date: Date
    @NSManaged var condition: Int
    @NSManaged var windSpeed: Float
    @NSManaged var rainAmount: Float
    @NSManaged var snowAmount: Float
    @NSManaged var minTemperature: Float
    @NSManaged var maxTemperature: Float
    @NSManaged var location: WeatherDb
    
    var model: DailyWeatherDb.Model {
        return DailyWeatherDb.Model(date: date, condition: condition, windSpeed: windSpeed, rainAmount: rainAmount, snowAmount: snowAmount, minTemperature: minTemperature, maxTemperature: maxTemperature, location: location.model)
    }
    
}

