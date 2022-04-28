//
//  CoreDataService+LocationWeather.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import RxSwift
import CoreData
import TWModels

extension CoreDataService: LocationWeatherStorageManaging {
    
    var cacheDuration: TimeInterval {
        return 10 * 60
    }
    
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> Completable {
        return Completable.create { observer in
            self.backgroundContext.performWith { ctx in
                let request: NSFetchRequest<WeatherDb> = self.getRequest(latitude: location.lat, longitude: location.lon)
                
                do {
                    let results: [WeatherDb] = try ctx.fetch(request)
                    let model: WeatherDb
                    
                    // Update existing model
                    if let m = results.first {
                        model = m
                        
                        // Check if the new model is newer
                        guard weather.current.lastUpdate > model.lastUpdate.timeIntervalSince1970 else {
                            observer(.completed)
                            return
                        }
                        
                        // Delete existing daily for this location
                        if let daily = model.daily as? Set<DailyWeatherDb> {
                            daily.forEach { weather in
                                ctx.delete(weather)
                            }
                        }
                    }
                    // Create a new model
                    else {
                        model = NSEntityDescription.insertNewObject(forEntityName: WeatherDb.Attributes.entityName, into: ctx) as! WeatherDb
                        model.location = try self.getDefaultWeatherLocation(location, context: ctx)
                    }
                    
                    self.updateModel(model, weather: weather, location: location, context: ctx)
                    
                    try ctx.save()
                    
                    observer(.completed)
                } catch {
                    print("Error saving location weather: \(error)")
                    observer(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func loadLocationWeather(latitude: Double, longitude: Double) -> Maybe<Weather.Overview.Response> {
        return Maybe.create { maybe in
            self.backgroundContext.performWith { ctx in
                let request: NSFetchRequest<WeatherDb> = self.getRequest(latitude: latitude, longitude: longitude)
                
                do {
                    let results: [WeatherDb] = try ctx.fetch(request)
                    
                    if let model = results.first, let overview = self.getOverview(fromModel: model) {
                        maybe(.success(overview))
                    } else {
                        maybe(.completed)
                    }
                } catch {
                    maybe(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func getRequest(latitude: Double, longitude: Double) -> NSFetchRequest<WeatherDb> {
        let request = NSFetchRequest<WeatherDb>(entityName: WeatherDb.Attributes.entityName)
        request.predicate = self.getPredicate(latitude: latitude, longitude: longitude)
        request.fetchLimit = 1
        return request
    }
    
    private func getOverview(fromModel model: WeatherDb) -> Weather.Overview.Response? {
        let weather: Weather.Info.Response = Weather.Info.Response(id: model.condition, description: model.conditionDescription, isNight: model.isNight)
        let current: Weather.Current.Response = Weather.Current.Response(weather: weather, lastUpdate: model.lastUpdate.timeIntervalSince1970, sunrise: model.sunrise.timeIntervalSince1970, sunset: model.sunset.timeIntervalSince1970, temperature: model.temperature, windSpeed: model.windSpeed, rain: model.rainAmount, snow: model.snowAmount)
        
        guard let models = model.daily as? Set<DailyWeatherDb> else {
            return nil
        }
        
        let daily: [Weather.Day.Response] = models.map({
            let weather: Weather.Info.Response = Weather.Info.Response(id: $0.condition, description: "", isNight: false)
            return Weather.Day.Response(date: $0.date.timeIntervalSince1970, weather: weather, tempMin: $0.minTemperature, tempMax: $0.maxTemperature, rain: $0.rainAmount, snow: $0.snowAmount, windSpeed: $0.windSpeed)
        }).sorted(by: {
            $0.date < $1.date
        })
        
        return Weather.Overview.Response(timezoneOffset: model.timezoneOffset, current: current, daily: daily)
    }
    
    private func updateModel(_ model: WeatherDb, weather: Weather.Overview.Response, location: WeatherLocation, context: NSManagedObjectContext) {
        model.condition = weather.current.weather.id
        model.conditionDescription = weather.current.weather.description
        model.lastUpdate = Date(timeIntervalSince1970: weather.current.lastUpdate)
        model.timezoneOffset = weather.timezoneOffset
        model.sunrise = Date(timeIntervalSince1970: weather.current.sunrise)
        model.sunset = Date(timeIntervalSince1970: weather.current.sunset)
        model.windSpeed = weather.current.windSpeed
        model.rainAmount = weather.current.rain
        model.snowAmount = weather.current.snow
        model.temperature = weather.current.temperature
        model.isNight = weather.current.weather.isNight
        
        self.updateLocationModel(model.location, location: location, context: context)
        
        let daily: [DailyWeatherDb] = weather.daily.map {
            self.getDailyModel(response: $0, location: model, context: context)
        }
        
        model.daily = NSSet(array: daily)
    }
    
    private func updateLocationModel(_ model: LocationDb, location: WeatherLocation, context: NSManagedObjectContext) {
        model.name = location.name
        model.country = location.country
        model.state = location.state
        model.lon = location.lon
        model.lat = location.lat
    }
    
    private func getDefaultWeatherLocation(_ location: WeatherLocation, context: NSManagedObjectContext) throws -> LocationDb {
        let model: LocationDb
        
        if let existing = try self.loadLocation(latitude: location.lat, longitude: location.lon, context: context) {
            model = existing
        } else {
            model = NSEntityDescription.insertNewObject(forEntityName: LocationDb.Attributes.entityName, into: context) as! LocationDb
            model.isDefault = false
        }
        
        return model
    }
    
    private func getDailyModel(response: Weather.Day.Response, location: WeatherDb, context: NSManagedObjectContext) -> DailyWeatherDb {
        let model: DailyWeatherDb = NSEntityDescription.insertNewObject(forEntityName: DailyWeatherDb.Attributes.entityName, into: context) as! DailyWeatherDb
        
        model.date = Date(timeIntervalSince1970: response.date)
        model.condition = response.weather.id
        model.windSpeed = response.windSpeed
        model.rainAmount = response.rain
        model.snowAmount = response.snow
        model.minTemperature = response.tempMin
        model.maxTemperature = response.tempMax
        model.location = location
        
        return model
    }
    
    private func getPredicate(latitude: Double, longitude: Double) -> NSPredicate {
        let e: Double = 0.0001
        return NSPredicate(format: "(location.lat > %lf AND location.lat < %lf) AND (location.lon > %lf AND location.lon < %lf)", latitude - e, latitude + e, longitude - e, longitude + e)
    }
    
}
