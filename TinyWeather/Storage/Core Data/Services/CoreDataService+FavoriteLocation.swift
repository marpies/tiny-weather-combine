//
//  CoreDataService+FavoriteLocation.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import Combine
import TWModels
import CoreData

extension CoreDataService: FavoriteLocationStorageManaging {
    
    func loadLocationFavoriteStatus(_ location: WeatherLocation) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future<Bool, Error> { future in
                self.backgroundContext.performWith { ctx in
                    do {
                        let model: LocationDb? = try self.loadLocation(latitude: location.lat, longitude: location.lon, context: ctx)
                        let isFavorite: Bool = model?.isFavorite ?? false
                        future(.success(isFavorite))
                    } catch {
                        future(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func saveLocationFavoriteStatus(_ location: WeatherLocation, isFavorite: Bool) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future<Bool, Error> { future in
                self.backgroundContext.performWith { ctx in
                    do {
                        if let model = try self.loadLocation(latitude: location.lat, longitude: location.lon, context: ctx) {
                            model.isFavorite = isFavorite
                            
                            try ctx.saveIfNeeded()
                            
                            future(.success(isFavorite))
                        } else {
                            future(.success(false))
                        }
                    } catch {
                        future(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func loadFavoriteLocations() -> AnyPublisher<[WeatherLocation], Error> {
        Deferred {
            Future<[WeatherLocation], Error> { future in
                self.backgroundContext.performWith { ctx in
                    do {
                        let request: NSFetchRequest<LocationDb> = NSFetchRequest(entityName: LocationDb.Attributes.entityName)
                        request.predicate = NSPredicate(format: "isFavorite == true")
                        
                        let locations: [LocationDb.Model] = try ctx.fetch(request).map { $0.model }
                        future(.success(locations))
                    } catch {
                        future(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
}
