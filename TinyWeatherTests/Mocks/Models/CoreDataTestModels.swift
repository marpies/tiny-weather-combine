//
//  CoreDataTestModels.swift
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
import TWModels
@testable import TinyWeather

enum CoreDataTestModels {
    @discardableResult static func createLocation(_ location: WeatherLocation, isDefault: Bool, isFavorite: Bool, context: NSManagedObjectContext) -> LocationDb {
        let result: LocationDb = NSEntityDescription.insertNewObject(forEntityName: LocationDb.Attributes.entityName, into: context) as! LocationDb
        result.name = location.name
        result.country = location.country
        result.state = location.state
        result.lat = location.lat
        result.lon = location.lon
        result.isDefault = isDefault
        result.isFavorite = isFavorite
        result.weather = nil
        return result
    }
    
    @discardableResult static func createWeather(location: WeatherLocation, weather: Weather.Overview.Response, context: NSManagedObjectContext) -> WeatherDb {
        let currentWeather = weather.current
        let locationModel = self.createLocation(location, isDefault: false, isFavorite: false, context: context)
        
        let result: WeatherDb = NSEntityDescription.insertNewObject(forEntityName: WeatherDb.Attributes.entityName, into: context) as! WeatherDb
        result.location = locationModel
        result.condition = currentWeather.weather.id
        result.conditionDescription = currentWeather.weather.description
        result.lastUpdate = Date(timeIntervalSince1970: currentWeather.lastUpdate)
        result.timezoneOffset = weather.timezoneOffset
        result.sunrise = Date(timeIntervalSince1970: currentWeather.sunrise)
        result.sunset = Date(timeIntervalSince1970: currentWeather.sunset)
        result.windSpeed = currentWeather.windSpeed
        result.rainAmount = currentWeather.rain
        result.snowAmount = currentWeather.snow
        result.temperature = currentWeather.temperature
        result.isNight = currentWeather.weather.isNight
        
        let daily: [DailyWeatherDb] = weather.daily.map({ daily in
            let model: DailyWeatherDb = NSEntityDescription.insertNewObject(forEntityName: DailyWeatherDb.Attributes.entityName, into: context) as! DailyWeatherDb
            model.date = Date(timeIntervalSince1970: daily.date)
            model.condition = daily.weather.id
            model.windSpeed = daily.windSpeed
            model.rainAmount = daily.rain
            model.snowAmount = daily.snow
            model.minTemperature = daily.tempMin
            model.maxTemperature = daily.tempMax
            model.location = result
            return model
        })
        
        result.daily = NSSet(array: daily)
        return result
    }
}
