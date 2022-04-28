//
//  CoordinatesPresenting.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

protocol CoordinatesPresenting {
    func getCoords(lat: Double, lon: Double) -> String
}

extension CoordinatesPresenting {
    
    func getCoords(lat: Double, lon: Double) -> String {
        let latAbbr: String
        let lonAbbr: String
        var latValue: Double = lat
        var lonValue: Double = lon
        
        if lat < 0 {
            latValue = abs(latValue)
            latAbbr = NSLocalizedString("latitudeSouthAbbreviation", comment: "")
        } else {
            latAbbr = NSLocalizedString("latitudeNorthAbbreviation", comment: "")
        }
        
        if lon < 0 {
            lonValue = abs(lonValue)
            lonAbbr = NSLocalizedString("longitudeWestAbbreviation", comment: "")
        } else {
            lonAbbr = NSLocalizedString("longitudeEastAbbreviation", comment: "")
        }
        
        let latFormat: String = String(format: "%.2f", latValue).replacingOccurrences(of: ".", with: "°")
        let lonFormat: String = String(format: "%.2f", lonValue).replacingOccurrences(of: ".", with: "°")
        
        return "\(latFormat)'\(latAbbr) \(lonFormat)'\(lonAbbr)"
    }
    
}
