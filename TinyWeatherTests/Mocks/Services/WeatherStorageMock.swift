//
//  WeatherStorageMock.swift
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
import Combine
@testable import TinyWeather

class WeatherStorageMock: WeatherStorageManaging {
    
    var defaultLocationResponse: WeatherLocation?
    var locationWeatherResponse: Weather.Overview.Response?
    var shouldFail: Bool = false
    
    var cacheDuration: TimeInterval = 0
    
    var numDefaultLocationCalls: Int = 0
    var defaultLocation: AnyPublisher<WeatherLocation?, Error> {
        Deferred {
            Future<WeatherLocation?, Error> { future in
                self.numDefaultLocationCalls += 1
                if let location = self.defaultLocationResponse {
                    future(.success(location))
                } else if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(nil))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numSaveDefaultLocationCalls: Int = 0
    func saveDefaultLocation(_ location: WeatherLocation) -> AnyPublisher<Void, Error> {
        Deferred {
            Future<Void, Error> { future in
                self.numSaveDefaultLocationCalls += 1
                
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numLoadLocationWeatherCalls: Int = 0
    func loadLocationWeather(latitude: Double, longitude: Double) -> Maybe<Weather.Overview.Response> {
        Maybe.create { maybe in
            self.numLoadLocationWeatherCalls += 1
            if let weather = self.locationWeatherResponse {
                maybe(.success(weather))
            } else if self.shouldFail {
                maybe(.error(MockError.forcedError))
            } else {
                maybe(.completed)
            }
            return Disposables.create()
        }
    }
    
    var numSaveLocationWeatherCalls: Int = 0
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> Completable {
        Completable.create { observer in
            self.numSaveLocationWeatherCalls += 1
            
            if self.shouldFail {
                observer(.error(MockError.forcedError))
            } else {
                observer(.completed)
            }
            
            return Disposables.create()
        }
    }
    
    var numLoadLocationFavoriteStatusCalls: Int = 0
    var loadLocationFavoriteStatusValue: Bool = false
    func loadLocationFavoriteStatus(_ location: WeatherLocation) -> Single<Bool> {
        Single.create { single in
            self.numLoadLocationFavoriteStatusCalls += 1
            
            if self.shouldFail {
                single(.failure(MockError.forcedError))
            } else {
                single(.success(self.loadLocationFavoriteStatusValue))
            }
            
            return Disposables.create()
        }
    }
    
    var numSaveLocationFavoriteStatusCalls: Int = 0
    var saveLocationFavoriteStatusArgumentValue: Bool = false
    func saveLocationFavoriteStatus(_ location: WeatherLocation, isFavorite: Bool) -> Single<Bool> {
        Single.create { single in
            self.saveLocationFavoriteStatusArgumentValue = isFavorite
            self.numSaveLocationFavoriteStatusCalls += 1
            
            if self.shouldFail {
                single(.failure(MockError.forcedError))
            } else {
                single(.success(isFavorite))
            }
            
            return Disposables.create()
        }
    }
    
    var numLoadFavoriteLocationsCalls: Int = 0
    var favoriteLocations: [WeatherLocation] = []
    func loadFavoriteLocations() -> Single<[WeatherLocation]> {
        Single.create { single in
            self.numLoadFavoriteLocationsCalls += 1
            
            if self.shouldFail {
                single(.failure(MockError.forcedError))
            } else {
                single(.success(self.favoriteLocations))
            }
            
            return Disposables.create()
        }
    }
    
}
