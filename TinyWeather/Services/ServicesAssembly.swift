//
//  ServicesAssembly.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský on 30.04.2022.
//  Copyright (c) 2022 Marcel Piestansky. All rights reserved.
//

import Foundation
import Swinject

struct ServicesAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(LocationManager.self) { r in
            return ReactiveLocationManager()
        }.inObjectScope(.container)
    }
    
}
