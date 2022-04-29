//
//  Binder.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

public struct Binder<Value> {
    
    private let binding: (Value) -> Void
    
    public init<Target: AnyObject>(_ target: Target, binding: @escaping (Target, Value) -> Void) {
        weak var weakTarget = target
        self.binding = { (value: Value) in
            if let t = weakTarget {
                binding(t, value)
            }
        }
    }
    
    public func sink(value: Value) {
        self.binding(value)
    }
    
}
