//
//  CoreDataAssembly.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import Swinject

struct CoreDataAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(CoreDataStoreProviding.self) { r in
            return CoreDataStore(inMemory: false)
        }
        container.register(CoreDataService.self) { r in
            let store: CoreDataStoreProviding = r.resolve(CoreDataStoreProviding.self)!
            return CoreDataService(store: store)
        }.inObjectScope(.container)
        container.register(DefaultLocationStorageManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(LocationWeatherStorageManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(FavoriteLocationStorageManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(WeatherStorageManaging.self) { r in
            return r.resolve(CoreDataService.self)!
        }
        container.register(StorageService.self) { r in
            return r.resolve(CoreDataService.self)!
        }
    }
    
}
