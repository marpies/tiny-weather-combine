//
//  SetupAssembly.swift
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
import TWRoutes

struct SetupAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(SetupViewModelProtocol.self) { (r: Resolver, router: WeakRouter<AppRoute>) in
            let theme: Theme = r.resolve(Theme.self)!
            let storage: StorageService = r.resolve(StorageService.self)!
            return SetupViewModel(theme: theme, router: router, storage: storage)
        }
        container.register(SetupViewController.self) { (r: Resolver, viewModel: SetupViewModelProtocol) in
            return SetupViewController(viewModel: viewModel)
        }
    }
    
}
