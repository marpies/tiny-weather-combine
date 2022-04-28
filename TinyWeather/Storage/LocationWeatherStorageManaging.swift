//
//  LocationWeatherStorageManaging.swift
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

protocol LocationWeatherStorageManaging {
    var cacheDuration: TimeInterval { get }
    
    func loadLocationWeather(latitude: Double, longitude: Double) -> Maybe<Weather.Overview.Response>
    func saveLocationWeather(_ weather: Weather.Overview.Response, location: WeatherLocation) -> Completable
}
