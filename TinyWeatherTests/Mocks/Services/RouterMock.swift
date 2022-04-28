//
//  RouterMock.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import TWRoutes
@testable import TinyWeather

class RouterMock: Router {
    typealias RouteType = AppRoute
    
    var calledRoute: AppRoute?
    var numRouteCalls: Int = 0
    
    func route(to route: AppRoute) {
        self.calledRoute = route
        self.numRouteCalls += 1
    }
}
