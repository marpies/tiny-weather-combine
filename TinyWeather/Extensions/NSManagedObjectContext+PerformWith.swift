//
//  NSManagedObjectContext+PerformWith.swift
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

extension NSManagedObjectContext {
    
    func performWith(block: @escaping (NSManagedObjectContext) -> Void) {
        self.perform {
            block(self)
        }
    }
    
    func performAndWaitWith(block: @escaping (NSManagedObjectContext) -> Void) {
        self.performAndWait {
            block(self)
        }
    }
    
}
