//
//  HTTPResponse.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

struct HTTPResponse {
    let request: URLRequest
    let data: Data?
    let response: HTTPURLResponse?
    
    func map<T: Decodable>(to type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let data = self.data else {
            throw NetworkError.decodingError(nil)
        }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
