//
//  TestExtensions.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

extension Dictionary where Key == String, Value == Any {
    
    var asData: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func double(_ key: String) -> Double {
        return (self[key] as? Double) ?? 0
    }
    
    func int(_ key: String) -> Int {
        return (self[key] as? Int) ?? 0
    }
    
    func string(_ key: String) -> String {
        return self.stringOptional(key) ?? ""
    }
    
    func stringOptional(_ key: String) -> String? {
        return self[key] as? String
    }
    
}

extension Array where Element == [String: Any] {
    
    var asData: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
}
