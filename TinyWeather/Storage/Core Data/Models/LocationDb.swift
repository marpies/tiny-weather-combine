//
//  LocationDb.swift
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

class LocationDb: NSManagedObject {
    
    enum Attributes {
        static let entityName: String = "LocationDb"
    }
    
    struct Model: WeatherLocation {
        let name: String
        let state: String?
        let country: String
        let lon: Double
        let lat: Double
        let isDefault: Bool
        let isFavorite: Bool
    }

    @NSManaged var name: String
    @NSManaged var country: String
    @NSManaged var state: String?
    @NSManaged var lon: Double
    @NSManaged var lat: Double
    @NSManaged var isDefault: Bool
    @NSManaged var isFavorite: Bool
    @NSManaged var weather: WeatherDb?
    
    var model: LocationDb.Model {
        return LocationDb.Model(name: name, state: state, country: country, lon: lon, lat: lat, isDefault: isDefault, isFavorite: isFavorite)
    }

}
