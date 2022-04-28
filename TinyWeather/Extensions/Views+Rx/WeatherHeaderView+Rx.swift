//
//  WeatherHeaderView+Rx.swift
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

extension Reactive where Base: WeatherHeaderView {
    
    var location: Binder<Weather.Location.ViewModel> {
        return Binder(self.base) { view, vm in
            view.updateLocation(viewModel: vm)
        }
    }
    
    var weather: Binder<Weather.Current.ViewModel> {
        return Binder(self.base) { view, vm in
            view.updateWeather(viewModel: vm)
        }
    }
    
    var showLoading: Binder<Void> {
        return Binder(self.base) { view, _ in
            view.showLoading()
        }
    }
    
    var hideLoading: Binder<Void> {
        return Binder(self.base) { view, _ in
            view.hideLoading()
        }
    }
    
}
