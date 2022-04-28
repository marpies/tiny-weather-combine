//
//  FavoritesTableDataSource+Rx.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: FavoritesTableDataSource {
    
    var viewModel: Binder<[Search.Location.ViewModel]> {
        return Binder(self.base) { ds, vm in
            ds.update(viewModel: vm)
        }
    }
    
}
