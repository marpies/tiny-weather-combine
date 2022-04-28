//
//  SearchModels.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import UIKit
import RxCocoa
import TWModels

enum Search {
    
    struct Model {
        let hints: BehaviorRelay<[Search.Location.Response]?> = BehaviorRelay(value: nil)
        let favorites: BehaviorRelay<[WeatherLocation]?> = BehaviorRelay(value: nil)
        
        func getHintLocation(at index: Int) -> Search.Location.Response? {
            if index >= 0, let locations = self.hints.value, index < locations.count {
                return locations[index]
            }
            return nil
        }
        
        func getFavoriteLocation(at index: Int) -> WeatherLocation? {
            if index >= 0, let locations = self.favorites.value, index < locations.count {
                return locations[index]
            }
            return nil
        }
        
        func removeFavoriteLocation(at index: Int) {
            if index >= 0, var locations = self.favorites.value, index < locations.count {
                locations.remove(at: index)
                self.favorites.accept(locations)
            }
        }
    }
    
    enum AnimationState {
        /// Animation is in the hidden state.
        case hidden
        
        /// Animation is in the visible state.
        case visible
        
        /// Returns the opposite state.
        var opposite: Search.AnimationState {
            switch self {
            case .hidden:
                return .visible
            case .visible:
                return .hidden
            }
        }
    }
    
    enum Location {
        struct Response: Codable, WeatherLocation {
            let name: String
            let state: String?
            let country: String
            let lon: Double
            let lat: Double
        }
        
        struct ViewModel: Hashable {
            let id: UUID = UUID()
            let flag: UIImage?
            let title: String
            let subtitle: String
            
            static func == (lhs: Search.Location.ViewModel, rhs: Search.Location.ViewModel) -> Bool {
                return lhs.id == rhs.id
            }
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(self.id)
            }
        }
    }
    
    enum SearchHints {
        case loading
        case empty(message: String)
        case results(cities: [Search.Location.ViewModel])
        case error(message: String)
    }
    
    enum Favorites {
        enum ViewModel {
            case none(String)
            case saved(String, [Search.Location.ViewModel])
        }
    }
    
}
