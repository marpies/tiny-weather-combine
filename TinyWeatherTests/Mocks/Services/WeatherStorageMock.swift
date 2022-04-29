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
    func loadLocationWeather(latitude: Double, longitude: Double) -> AnyPublisher<Weather.Overview.Response?, Error> {
        Deferred {
            Future<Weather.Overview.Response?, Error> { future in
                self.numLoadLocationWeatherCalls += 1
                if let weather = self.locationWeatherResponse {
                    future(.success(weather))
                } else if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(nil))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numSaveLocationWeatherCalls: Int = 0
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> AnyPublisher<Void, Error> {
        Deferred {
            Future<Void, Error> { future in
                self.numSaveLocationWeatherCalls += 1
                
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numLoadLocationFavoriteStatusCalls: Int = 0
    var loadLocationFavoriteStatusValue: Bool = false
    func loadLocationFavoriteStatus(_ location: WeatherLocation) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future<Bool, Error> { future in
                self.numLoadLocationFavoriteStatusCalls += 1
                
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(self.loadLocationFavoriteStatusValue))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numSaveLocationFavoriteStatusCalls: Int = 0
    var saveLocationFavoriteStatusArgumentValue: Bool = false
    func saveLocationFavoriteStatus(_ location: WeatherLocation, isFavorite: Bool) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future<Bool, Error> { future in
                self.saveLocationFavoriteStatusArgumentValue = isFavorite
                self.numSaveLocationFavoriteStatusCalls += 1
                
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(isFavorite))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    var numLoadFavoriteLocationsCalls: Int = 0
    var favoriteLocations: [WeatherLocation] = []
    func loadFavoriteLocations() -> AnyPublisher<[WeatherLocation], Error> {
        Deferred {
            Future<[WeatherLocation], Error> { future in
                self.numLoadFavoriteLocationsCalls += 1
                
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    future(.success(self.favoriteLocations))
                }
            }
        }.eraseToAnyPublisher()
    }
    
}
