//
//  CoreDataService+DefaultLocation.swift
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
import RxSwift
import TWModels

extension CoreDataService: DefaultLocationStorageManaging {
    
    var defaultLocation: Maybe<WeatherLocation> {
        return Maybe.create { maybe in
            self.backgroundContext.performWith { ctx in
                let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
                request.predicate = NSPredicate(format: "isDefault == true")
                request.fetchLimit = 1
                
                do {
                    let results: [LocationDb] = try ctx.fetch(request)
                    if let model = results.first?.model {
                        maybe(.success(model))
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
    
    func saveDefaultLocation(_ location: WeatherLocation) -> Completable {
        return Completable.create { observer in
            self.backgroundContext.performWith { ctx in
                do {
                    // Remove default flag from existing default location model
                    try self.clearDefaultLocation(context: ctx)
                    
                    // Set the default flag on the new location
                    // Update existing model or create a new one
                    let existing: LocationDb? = try self.loadLocation(latitude: location.lat, longitude: location.lon, context: ctx)
                    let model: LocationDb = existing ?? NSEntityDescription.insertNewObject(forEntityName: LocationDb.Attributes.entityName, into: ctx) as! LocationDb
                    
                    model.name = location.name
                    model.country = location.country
                    model.state = location.state
                    model.lon = location.lon
                    model.lat = location.lat
                    model.isDefault = true
                    
                    try ctx.saveIfNeeded()
                    
                    observer(.completed)
                } catch {
                    print("Error saving default location: \(error)")
                    observer(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func clearDefaultLocation(context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
        request.predicate = NSPredicate(format: "isDefault == true")
        
        let results: [LocationDb] = try context.fetch(request)
        
        results.forEach { location in
            location.isDefault = false
        }
    }
    
}
