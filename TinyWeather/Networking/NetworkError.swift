//
//  NetworkError.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

enum NetworkError: Error {
    case decodingError(Error?)
    case invalidRequest
    case invalidResponse
    case underlying(Error)
}
