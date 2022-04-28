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
import RxSwift
import TWModels

protocol FavoriteLocationStorageManaging {
    func loadLocationFavoriteStatus(_ location: WeatherLocation) -> Single<Bool>
    func saveLocationFavoriteStatus(_ location: WeatherLocation, isFavorite: Bool) -> Single<Bool>
    func loadFavoriteLocations() -> Single<[WeatherLocation]>
}
