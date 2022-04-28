//
//  WeatherAttributesView.swift
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

class WeatherAttributesView: UIStackView {
    
    private let theme: Theme
    private let style: WeatherAttributeView.Style

    init(theme: Theme, style: WeatherAttributeView.Style) {
        self.theme = theme
        self.style = style
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: [Weather.Attribute.ViewModel]) {
        for view in self.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        for vm in viewModel {
            let view: WeatherAttributeView = WeatherAttributeView(theme: self.theme, style: self.style)
            view.update(viewModel: vm)
            self.addArrangedSubview(view)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        switch self.style {
        case .small:
            self.spacing = 8
            self.axis = .vertical
            self.alignment = .center
            
        case .large:
            self.axis = .horizontal
            self.spacing = 24
        }
    }

}
