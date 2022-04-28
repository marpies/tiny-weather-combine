//
//  DailyWeatherView+Rx.swift
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

extension Reactive where Base: DailyWeatherView {

    var newDailyWeather: Binder<Weather.Day.ViewModel> {
        return Binder(self.base) { view, vm in
            view.add(viewModel: vm)
        }
    }

    var removeAll: Binder<Void> {
        return Binder(self.base) { view, _ in
            view.removeAll()
        }
    }

}
