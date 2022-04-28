//
//  Observable+Interval.swift
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

extension Observable {
    
    /// https://stackoverflow.com/a/61676478
    func with(interval: RxTimeInterval) -> Observable {
        return enumerated()
            .concatMap { index, element in
                Observable
                    .just(element)
                    .delay(index == 0 ? RxTimeInterval.seconds(0) : interval,
                           scheduler: MainScheduler.instance)
            }
    }
    
}
