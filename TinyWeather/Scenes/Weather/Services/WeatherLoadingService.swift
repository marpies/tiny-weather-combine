//
//  WeatherLoadingService.swift
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

struct WeatherLoadingService: WeatherLoading {
    
    let storage: LocationWeatherStorageManaging
    let apiService: RequestExecuting

    init(storage: LocationWeatherStorageManaging, apiService: RequestExecuting) {
        self.storage = storage
        self.apiService = apiService
    }
    
    func loadWeather(latitude: Double, longitude: Double) -> AnyPublisher<Weather.Overview.Response, Error> {
        return self.storage.loadLocationWeather(latitude: latitude, longitude: longitude)
            .map({ (weather: Weather.Overview.Response?) -> Weather.Overview.Response? in
                if self.isCacheRecent(weather?.current) {
                    return weather
                }
                return nil
            })
            .catch({ _ in
                Just(nil)
            })
            .setFailureType(to: Error.self)
            .flatMap({ (r: Weather.Overview.Response?) -> AnyPublisher<Weather.Overview.Response, Error> in
                if let response = r {
                    return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                return self.apiService
                    .execute(request: APIResource.currentAndDaily(lat: latitude, lon: longitude))
                    .tryMap({ (response: HTTPResponse) in
                        try response.map(to: Weather.Overview.Response.self)
                    })
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    //
    // MARK: - Private
    //
    
    private func isCacheRecent(_ weather: Weather.Current.Response?) -> Bool {
        guard let weather = weather else { return false }
        
        let threshold: TimeInterval = Date().timeIntervalSince1970 - self.storage.cacheDuration
        return weather.lastUpdate > threshold
    }
    
}
