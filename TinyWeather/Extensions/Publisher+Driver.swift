//
//  Publisher+Driver.swift
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
    
    func asDriver(onErrorJustReturn output: Output) -> AnyPublisher<Output, Never> {
        return self.receive(on: DispatchQueue.main).replaceError(with: output).eraseToAnyPublisher()
    }
    
}
