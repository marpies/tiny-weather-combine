//
//  URLSessions+RequestExecuting.swift
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

struct DefaultRequestExecutor: RequestExecuting {
    func execute(request requestProvider: RequestProviding) -> AnyPublisher<HTTPResponse, Error> {
        guard let request = requestProvider.request else {
            return Fail(error: NetworkError.invalidRequest).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map({ data in
                HTTPResponse(request: request, data: data.data, response: data.response as? HTTPURLResponse)
            })
            .mapError({ error in
                error as Error
            })
            .eraseToAnyPublisher()
    }
}
