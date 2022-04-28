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
import RxSwift
import TWModels
@testable import TinyWeather

class LocationWeatherStorageTestMock: LocationWeatherStorageManaging {
    
    var shouldFail: Bool = false
    var weather: Weather.Overview.Response!
    var cacheDuration: TimeInterval = 0
    
    func loadLocationWeather(latitude: Double, longitude: Double) -> Maybe<Weather.Overview.Response> {
        return Maybe.create { maybe in
            if self.shouldFail {
                maybe(.error(MockError.forcedError))
            } else {
                maybe(.success(self.weather))
            }
            return Disposables.create()
        }
    }
    
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> Completable {
        return Completable.create { observer in
            observer(.completed)
            
            return Disposables.create()
        }
    }
    
}
