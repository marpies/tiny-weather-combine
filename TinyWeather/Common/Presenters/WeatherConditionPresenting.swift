//
//  WeatherConditionPresenting.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import TWThemes
import TWModels

protocol WeatherConditionPresenting {
    func getConditionIcon(weather: Weather.Info.Response, colors: WeatherColors) -> DuotoneIcon.ViewModel
}

extension WeatherConditionPresenting {
    
    func getConditionIcon(weather: Weather.Info.Response, colors: WeatherColors) -> DuotoneIcon.ViewModel {
        let isNight: Bool = weather.isNight
        
        switch weather.condition {
        case .thunderstorm:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .thunderstormMoon, primaryColor: colors.cloud, secondaryColor: colors.moon)
            }
            return DuotoneIcon.ViewModel(icon: .thunderstorm, primaryColor: colors.cloud, secondaryColor: colors.bolt)
        case .drizzle, .lightRain:
            return DuotoneIcon.ViewModel(icon: .cloudDrizzle, primaryColor: colors.cloud, secondaryColor: colors.rain)
        case .rain:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .cloudMoonRain, primaryColor: colors.cloud, secondaryColor: colors.moon)
            }
            return DuotoneIcon.ViewModel(icon: .cloudRain, primaryColor: colors.cloud, secondaryColor: colors.rain)
        case .showerRain:
            return DuotoneIcon.ViewModel(icon: .cloudShowers, primaryColor: colors.cloud, secondaryColor: colors.rain)
        case .freezingRain:
            return DuotoneIcon.ViewModel(icon: .cloudHailMixed, primaryColor: colors.cloud, secondaryColor: colors.snow)
        case .heavyRain:
            return DuotoneIcon.ViewModel(icon: .cloudShowersHeavy, primaryColor: colors.cloud, secondaryColor: colors.rain)
        case .snow:
            return DuotoneIcon.ViewModel(icon: .snowflakes, color: colors.snow)
        case .lightSnow:
            return DuotoneIcon.ViewModel(icon: .cloudSnow, primaryColor: colors.cloud, secondaryColor: colors.snow)
        case .atmosphere:
            return DuotoneIcon.ViewModel(icon: .smog, primaryColor: colors.cloud, secondaryColor: colors.fog)
        case .clear:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .moonStars, primaryColor: colors.moon, secondaryColor: colors.stars)
            }
            return DuotoneIcon.ViewModel(icon: .sun, color: colors.sun)
        case .fewClouds:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .moonCloud, primaryColor: colors.cloud, secondaryColor: colors.moon)
            }
            return DuotoneIcon.ViewModel(icon: .sunCloud, primaryColor: colors.cloud, secondaryColor: colors.sun)
        case .scatteredClouds:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .cloudMoon, primaryColor: colors.cloud, secondaryColor: colors.moon)
            }
            return DuotoneIcon.ViewModel(icon: .cloudSun, primaryColor: colors.cloud, secondaryColor: colors.sun)
        case .clouds:
            if isNight {
                return DuotoneIcon.ViewModel(icon: .cloudsMoon, primaryColor: colors.cloud, secondaryColor: colors.moon)
            }
            return DuotoneIcon.ViewModel(icon: .clouds, color: colors.cloud)
        }
    }
    
}
