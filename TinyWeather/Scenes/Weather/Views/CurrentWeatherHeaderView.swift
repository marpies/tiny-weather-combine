//
//  CurrentWeatherHeaderView.swift
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
import TWModels

class CurrentWeatherHeaderView: UIStackView {

    private let theme: Theme
    private let iconView: DuotoneLabel
    private let temperatureLabel: UILabel = UILabel()
    private let descriptionLabel: UILabel = UILabel()
    
    init(theme: Theme) {
        self.theme = theme
        self.iconView = DuotoneLabel(theme: theme)
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(icon: DuotoneIcon.ViewModel, temperature: String, description: String) {
        self.iconView.updateIcon(viewModel: icon)
        self.temperatureLabel.text = temperature
        self.descriptionLabel.text = description
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .horizontal
        self.spacing = 24
        
        self.iconView.setSize(108)
        self.iconView.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.iconView)
        
        // Temperature + description
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        self.addArrangedSubview(stack)
        
        self.temperatureLabel.font = self.theme.fonts.primaryBold(size: 56)
        self.temperatureLabel.textColor = self.theme.colors.label
        self.temperatureLabel.backgroundColor = self.theme.colors.background
        stack.addArrangedSubview(self.temperatureLabel)
        
        self.descriptionLabel.font = self.theme.fonts.primary(style: .body)
        self.descriptionLabel.textColor = self.theme.colors.secondaryLabel
        self.descriptionLabel.textAlignment = .center
        self.descriptionLabel.numberOfLines = 2
        self.descriptionLabel.backgroundColor = self.theme.colors.background
        stack.addArrangedSubview(self.descriptionLabel)
    }

}
