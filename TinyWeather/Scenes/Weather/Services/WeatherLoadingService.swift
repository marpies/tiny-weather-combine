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
import RxSwift

struct WeatherLoadingService: WeatherLoading {
    
    let storage: LocationWeatherStorageManaging
    let apiService: RequestExecuting

    init(storage: LocationWeatherStorageManaging, apiService: RequestExecuting) {
        self.storage = storage
        self.apiService = apiService
    }
    
    func loadWeather(latitude: Double, longitude: Double) -> Single<Weather.Overview.Response> {
        return Single.create { single in
            // Load storage first, then API if no cache recent exists
            let loader = self.storage.loadLocationWeather(latitude: latitude, longitude: longitude)
                .filter({ (weather) in
                    self.isCacheRecent(weather.current)
                })
                .asObservable()
                .first()
                .catchAndReturn(nil)
                .flatMap({ (r: Weather.Overview.Response?) -> Single<Weather.Overview.Response> in
                    // Use the recent cache if we have it
                    if let response = r {
                        return Single.just(response)
                    }
                    
                    // Make an API call if needed
                    return self.apiService
                        .execute(request: APIResource.currentAndDaily(lat: latitude, lon: longitude))
                        .map({ (response: HTTPResponse) in
                            try response.map(to: Weather.Overview.Response.self)
                        })
                })
            
            let disposable = loader
                .subscribe(onSuccess: { weather in
                    single(.success(weather))
                }, onFailure: { error in
                    single(.failure(error))
                })
            
            return Disposables.create {
                disposable.dispose()
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func isCacheRecent(_ weather: Weather.Current.Response) -> Bool {
        let threshold: TimeInterval = Date().timeIntervalSince1970 - self.storage.cacheDuration
        return weather.lastUpdate > threshold
    }
    
}
