//
//  LocationManager.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import CoreLocation
import Combine

protocol LocationManager {
    var currentLocation: AnyPublisher<CLLocation, Never> { get }
}
