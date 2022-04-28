//
//  WeatherLoading.swift
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

protocol WeatherLoading {
    func loadWeather(latitude: Double, longitude: Double) -> AnyPublisher<Weather.Overview.Response, Error>
}
