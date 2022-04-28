//
//  WeatherAttributeView.swift
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

class WeatherAttributeView: UIStackView {
    
    enum Style {
        case small, large
    }
    
    private let theme: Theme
    private let titleLabel: UILabel = UILabel()
    private let iconView: DuotoneLabel

    init(theme: Theme, style: Style) {
        self.theme = theme
        self.iconView = DuotoneLabel(theme: theme)
        
        super.init(frame: .zero)
        
        self.setupView(style: style)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Weather.Attribute.ViewModel) {
        self.iconView.updateIcon(viewModel: viewModel.icon)
        self.titleLabel.text = viewModel.title
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView(style: Style) {
        self.alignment = .center
        
        self.iconView.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.iconView)
        
        self.titleLabel.textColor = self.theme.colors.label
        self.titleLabel.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.titleLabel)
        
        switch style {
        case .small:
            self.spacing = 8
            self.axis = .horizontal
            self.iconView.setStyle(.subheadline)
            self.titleLabel.font = self.theme.fonts.primary(style: .subheadline)
        case .large:
            self.spacing = 4
            self.axis = .vertical
            self.iconView.setStyle(.title1)
            self.titleLabel.font = self.theme.fonts.primary(style: .body)
        }
    }

}
