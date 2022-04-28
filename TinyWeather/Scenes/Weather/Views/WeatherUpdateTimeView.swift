//
//  WeatherUpdateTimeView.swift
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

class WeatherUpdateTimeView: UIStackView {
    
    private let theme: Theme
    private let titleLabel: UILabel = UILabel()
    private let iconView: DuotoneLabel
    private let timeLabel: UILabel = UILabel()

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
    
    func update(icon: DuotoneIcon.ViewModel, time: String) {
        self.iconView.updateIcon(viewModel: icon)
        self.timeLabel.text = time
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .vertical
        self.spacing = 8
        self.alignment = .center
        
        self.titleLabel.text = NSLocalizedString("currentWeatherLastUpdateTimeTitle", comment: "")
        self.titleLabel.font = self.theme.fonts.primary(style: .subheadline)
        self.titleLabel.textColor = self.theme.colors.secondaryLabel
        self.titleLabel.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.titleLabel)
        
        // Icon + time
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        self.addArrangedSubview(stack)
        
        self.iconView.setStyle(.body)
        self.iconView.setColor(self.theme.colors.label)
        self.iconView.backgroundColor = self.theme.colors.background
        stack.addArrangedSubview(self.iconView)
        
        self.timeLabel.font = self.theme.fonts.primary(style: .body)
        self.timeLabel.textColor = self.theme.colors.label
        self.timeLabel.backgroundColor = self.theme.colors.background
        stack.addArrangedSubview(self.timeLabel)
    }

}
