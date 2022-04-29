//
//  FavoriteLocationStorageManaging.swift
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

protocol FavoriteLocationStorageManaging {
    func loadLocationFavoriteStatus(_ location: WeatherLocation) -> AnyPublisher<Bool, Error>
    func saveLocationFavoriteStatus(_ location: WeatherLocation, isFavorite: Bool) -> AnyPublisher<Bool, Error>
    func loadFavoriteLocations() -> AnyPublisher<[WeatherLocation], Error>
}
