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
import RxSwift

struct DefaultRequestExecutor: RequestExecuting {
    func execute(request requestProvider: RequestProviding) -> Single<HTTPResponse> {
        return URLSession.shared.rx.execute(request: requestProvider)
    }
}

extension Reactive: RequestExecuting where Base: URLSession {
    
    func execute(request requestProvider: RequestProviding) -> Single<HTTPResponse> {
        Single.create { single in
            guard let request = requestProvider.request else {
                single(.failure(NetworkError.invalidRequest))
                return Disposables.create()
            }
            
            let task = self.base.dataTask(with: request) { data, response, error in
                if let r = response as? HTTPURLResponse, !(200..<300 ~= r.statusCode) {
                    single(.failure(NetworkError.invalidResponse))
                } else if let e = error {
                    single(.failure(NetworkError.underlying(e)))
                } else {
                    let r = HTTPResponse(request: request, data: data, response: response as? HTTPURLResponse)
                    single(.success(r))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
}
