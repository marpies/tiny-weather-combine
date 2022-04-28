//
//  WindSpeedPresenting.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import TWExtensions

protocol WindSpeedPresenting {
    func getWindSpeed(_ value: Float) -> String
}

extension WindSpeedPresenting {
    
    func getWindSpeed(_ value: Float) -> String {
        let rounded: String = value.rounded().format(".0")
        return "\(rounded) km/h"
    }
    
}
