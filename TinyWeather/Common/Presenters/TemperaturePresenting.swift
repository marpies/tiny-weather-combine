//
//  TemperaturePresenting.swift
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
import TWThemes
import TWExtensions

protocol TemperaturePresenting {
    func getTemperatureText(_ value: Float) -> String
    func getTemperatureShortText(_ value: Float) -> String
    func getTemperature(_ value: Float, theme: Theme) -> Weather.Temperature.ViewModel
}

extension TemperaturePresenting {
    
    func getTemperatureText(_ value: Float) -> String {
        let base: String = self.getTemperatureShortText(value)
        return "\(base)C"
    }
    
    func getTemperatureShortText(_ value: Float) -> String {
        var temp: Float = value.rounded()
        
        // Avoid showing negative zero
        if temp == 0 && temp.sign == .minus {
            temp = 0
        }
        
        let rounded: String = temp.format(".0")
        return "\(rounded)°"
    }
    
    func getTemperature(_ value: Float, theme: Theme) -> Weather.Temperature.ViewModel {
        let title: String = self.getTemperatureShortText(value)
        let color: UIColor
        let colors: TemperatureColors = theme.colors.temperatures
        
        switch value {
        case ..<(-25):
            color = colors.superCold.color
            
        case -25..<(-10):
            color = self.getTransitionColor(temp: value, minTemp: -25, maxTemp: -10, minColor: colors.superCold, maxColor: colors.cold)
            
        case -10..<0:
            color = self.getTransitionColor(temp: value, minTemp: -10, maxTemp: 0, minColor: colors.cold, maxColor: colors.zero)
        
        case 0..<4:
            color = colors.zero.color
            
        // Zero to neutral
        case 4..<10:
            color = self.getTransitionColor(temp: value, minTemp: 4, maxTemp: 10, minColor: colors.zero, maxColor: colors.neutral)
            
        // Neutral to warm
        case 10..<20:
            color = self.getTransitionColor(temp: value, minTemp: 10, maxTemp: 20, minColor: colors.neutral, maxColor: colors.warm)
            
        // Warm to hot
        case 20..<30:
            color = self.getTransitionColor(temp: value, minTemp: 20, maxTemp: 30, minColor: colors.warm, maxColor: colors.hot)
            
        // Hot to superhot
        case 30..<36:
            color = self.getTransitionColor(temp: value, minTemp: 30, maxTemp: 36, minColor: colors.hot, maxColor: colors.superHot)
            
        case 36...:
            color = colors.superHot.color
            
        default:
            color = colors.neutral.color
            assertionFailure("Invalid temperature")
        }
        
        return Weather.Temperature.ViewModel(title: title, color: color)
    }
    
    //
    // MARK: - Private
    //
    
    private func getTransitionColor(temp: Float, minTemp: Float, maxTemp: Float, minColor: DynamicColor, maxColor: DynamicColor) -> UIColor {
        let diff: Float = maxTemp - minTemp
        let progress: Float = (temp - minTemp) / diff
        return minColor.toColor(maxColor, percentage: CGFloat(progress))
    }
    
}
