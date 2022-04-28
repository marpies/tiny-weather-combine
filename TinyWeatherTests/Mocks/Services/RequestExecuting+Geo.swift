//
//  RequestExecuting+Geo.swift
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
@testable import TinyWeather

class RequestExecutingGeo: RequestExecuting {
    
    var requestTimestamp: TimeInterval = 0
    var numExecuteCalls: Int = 0
    var shouldFail: Bool = false
    var shouldRespondWithEmpty: Bool = false
    
    func execute(request: RequestProviding) -> AnyPublisher<HTTPResponse, Error> {
        return Deferred<Future<HTTPResponse, Error>> {
            self.numExecuteCalls += 1
            
            return Future<HTTPResponse, Error> { future in
                if self.shouldFail {
                    future(.failure(MockError.forcedError))
                } else {
                    let data: Data
                    
                    if self.shouldRespondWithEmpty {
                        data = ResponseGeo.emptyResponse.asData
                    } else {
                        data = ResponseGeo.successResponse.asData
                    }
                    
                    let response = HTTPResponse(request: request.request!, data: data, response: nil)
                    
                    future(.success(response))
                }
            }
        }.eraseToAnyPublisher()
    }
    
}
