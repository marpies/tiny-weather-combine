//
//  Publisher+AssignTo.swift
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

extension Publisher {
    
    func assign(to subject: PassthroughSubject<Output, Failure>) -> Cancellable {
        return self.sink(receiveCompletion: { [weak subject] completion in
            subject?.send(completion: completion)
        }, receiveValue: { [weak subject] output in
            subject?.send(output)
        })
    }
    
}
