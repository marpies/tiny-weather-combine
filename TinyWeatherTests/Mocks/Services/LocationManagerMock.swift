//
//  LocationManagerMock.swift
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
import CoreLocation
@testable import TinyWeather

class LocationManagerMock: LocationManager {
    var location: CLLocation = CLLocation(latitude: 10, longitude: 10)
    
    var currentLocation: AnyPublisher<CLLocation, Never> {
        Deferred {
            Future<CLLocation, Never> { future in
                future(.success(self.location))
            }
        }.eraseToAnyPublisher()
    }
}
