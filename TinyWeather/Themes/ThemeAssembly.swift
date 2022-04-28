//
//  ThemeAssembly.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import Foundation
import Swinject
import TWThemes

struct ThemeAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(Theme.self) { r in
            return AppTheme()
        }
    }
    
}
