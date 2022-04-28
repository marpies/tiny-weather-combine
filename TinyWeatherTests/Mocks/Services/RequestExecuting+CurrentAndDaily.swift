//
//  RequestExecuting+CurrentAndDaily.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import RxSwift
@testable import TinyWeather

class RequestExecutingCurrentAndDaily: RequestExecuting {
    
    var requestTimestamp: TimeInterval = 0
    var numExecuteCalls: Int = 0
    var shouldFail: Bool = false
    
    func execute(request: RequestProviding) -> Single<HTTPResponse> {
        return Single.create { single in
            self.numExecuteCalls += 1
            
            if self.shouldFail {
                single(.failure(MockError.forcedError))
            } else {
                let data: Data = ResponseCurrentAndDaily.getSuccessResponse(timestamp: self.requestTimestamp).asData
                let response = HTTPResponse(request: request.request!, data: data, response: nil)
                
                single(.success(response))
            }
            
            return Disposables.create()
        }
    }
    
}
