//
//  Response+Geo.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

enum ResponseGeo {
    static var successResponse: [[String: Any]] {
        return [
            [
                "name": "London",
                "lat": 51.5073219,
                "lon": -0.1276474,
                "country": "GB",
                "state": "England"
            ],
            [
                "name": "City of London",
                "lat": 51.5156177,
                "lon": -0.0919983,
                "country": "GB"
            ],
            [
                "name": "London",
                "lat": 42.9836747,
                "lon": -81.2496068,
                "country": "CA",
                "state": "Ontario"
            ],
            [
                "name": "London",
                "lat": 37.1289771,
                "lon": -84.0832646,
                "country": "US",
                "state": "Kentucky"
            ],
            [
                "name": "London",
                "lat": 39.8864493,
                "lon": -83.448253,
                "country": "US",
                "state": "Ohio"
            ]
        ]
    }
    
    static var emptyResponse: [[String: Any]] {
        return []
    }
}
