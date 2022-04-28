//
//  LocationWeatherStorageTestMock.swift
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
@testable import TinyWeather

class LocationWeatherStorageTestMock: LocationWeatherStorageManaging {
    
    var shouldFail: Bool = false
    var weather: Weather.Overview.Response!
    var cacheDuration: TimeInterval = 0
    
    func loadLocationWeather(latitude: Double, longitude: Double) -> AnyPublisher<Weather.Overview.Response?, Error> {
        return Deferred<Future<Weather.Overview.Response?, Error>> {
            Future<Weather.Overview.Response?, Error> { future in
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(self.weather))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> AnyPublisher<Void, Error> {
        return Deferred {
            Future<Void, Error> { future in
                future(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
}
