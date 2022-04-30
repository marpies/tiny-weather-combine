//
//  FavoriteLocationsView+Rx.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

extension Reactive where Base: FavoriteLocationsView {
    
    var viewModel: Binder<Search.Favorites.ViewModel> {
        return Binder(self.base) { view, vm in
            view.update(viewModel: vm)
        }
    }
    
}
