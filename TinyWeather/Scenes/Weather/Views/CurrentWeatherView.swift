//
//  CurrentWeatherView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import UIKit
import TWThemes

class CurrentWeatherView: UIStackView {
    
    private let theme: Theme
    private let headerView: CurrentWeatherHeaderView
    private let attributesView: WeatherAttributesView
    private let timeView: WeatherUpdateTimeView

    init(theme: Theme) {
        self.theme = theme
        self.headerView = CurrentWeatherHeaderView(theme: theme)
        self.attributesView = WeatherAttributesView(theme: theme, style: .large)
        self.timeView = WeatherUpdateTimeView(theme: theme)
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Weather.Current.ViewModel) {
        self.headerView.update(icon: viewModel.conditionIcon, temperature: viewModel.temperature, description: viewModel.description)
        self.attributesView.update(viewModel: viewModel.attributes)
        self.timeView.update(icon: viewModel.lastUpdateIcon, time: viewModel.lastUpdate)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .vertical
        self.spacing = 32
        self.alignment = .center
        
        self.addArrangedSubview(self.headerView)
        self.addArrangedSubview(self.attributesView)
        self.addArrangedSubview(self.timeView)
    }

}
