//
//  WeatherLoadingMock.swift
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
@testable import TinyWeather

class WeatherLoadingMock: WeatherLoading {
    
    var shouldFail: Bool = false
    var weather: Weather.Overview.Response!
    var numLoadWeatherCalls: Int = 0
    var numLoadWeatherSubscriptions: Int = 0
    
    func loadWeather(latitude: Double, longitude: Double) -> AnyPublisher<Weather.Overview.Response, Error> {
        self.numLoadWeatherCalls += 1
        
        return Deferred<Future<Weather.Overview.Response, Error>> {
            self.numLoadWeatherSubscriptions += 1
            
            return Future<Weather.Overview.Response, Error> { future in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.shouldFail {
                        future(.failure(MockError.forcedError))
                    } else {
                        future(.success(self.weather))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
}
