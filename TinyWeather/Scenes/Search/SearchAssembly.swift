//
//  SearchAssembly.swift
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

struct SearchAssembly: Assembly {
    
    func assemble(container: Container) {
        container.register(SearchViewModelProtocol.self) { (r: Resolver, router: WeakRouter<AppRoute>, isInteractiveAnimationEnabled: Bool) in
            let theme: Theme = r.resolve(Theme.self)!
            let apiService: RequestExecuting = r.resolve(RequestExecuting.self)!
            let storage: FavoriteLocationStorageManaging = r.resolve(FavoriteLocationStorageManaging.self)!
            return SearchViewModel(apiService: apiService, theme: theme, router: router, storage: storage, isInteractiveAnimationEnabled: isInteractiveAnimationEnabled)
        }
        container.register(SearchViewController.self) { (r: Resolver, viewModel: SearchViewModelProtocol) in
            return SearchViewController(viewModel: viewModel)
        }
    }
    
}
