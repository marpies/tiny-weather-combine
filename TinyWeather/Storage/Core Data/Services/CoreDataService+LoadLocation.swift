//
//  CoreDataService+LoadLocation.swift
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

extension CoreDataService {
    
    func loadLocation(latitude: Double, longitude: Double, context: NSManagedObjectContext) throws -> LocationDb? {
        let request = NSFetchRequest<LocationDb>(entityName: LocationDb.Attributes.entityName)
        request.predicate = self.getPredicate(latitude: latitude, longitude: longitude)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    //
    // MARK: - Private
    //
    
    private func getPredicate(latitude: Double, longitude: Double) -> NSPredicate {
        let e: Double = 0.0001
        return NSPredicate(format: "(lat > %lf AND lat < %lf) AND (lon > %lf AND lon < %lf)", latitude - e, latitude + e, longitude - e, longitude + e)
    }
    
}
