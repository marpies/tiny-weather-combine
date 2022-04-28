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
import RxSwift
@testable import TinyWeather

class WeatherLoadingMock: WeatherLoading {
    
    var shouldFail: Bool = false
    var weather: Weather.Overview.Response!
    var numLoadWeatherCalls: Int = 0
    var numLoadWeatherSubscriptions: Int = 0
    
    func loadWeather(latitude: Double, longitude: Double) -> Single<Weather.Overview.Response> {
        self.numLoadWeatherCalls += 1
        
        return Single.create { single in
            self.numLoadWeatherSubscriptions += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.shouldFail {
                    single(.failure(MockError.forcedError))
                } else {
                    single(.success(self.weather))
                }
            }
            
            return Disposables.create()
        }
    }
    
}
