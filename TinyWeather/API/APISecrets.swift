//
//  APISecrets.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

enum APISecrets {
    private static let _apiKey: String = ""
    
    static let apiKey: String = {
        assert(APISecrets._apiKey.isEmpty == false, "Set your API key")
        
        return APISecrets._apiKey
    }()
}
