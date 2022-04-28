//
//  WeatherErrorView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import UIKit
import TWThemes

class WeatherErrorView: UIStackView {
    
    let theme: Theme
    let iconView: DuotoneLabel
    let messageLabel: UILabel = UILabel()
    
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
    
    func update(viewModel: Weather.Error.ViewModel) {
        self.iconView.updateIcon(viewModel: viewModel.icon)
        self.messageLabel.text = viewModel.message
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .vertical
        self.spacing = 16
        self.alignment = .center
        
        self.iconView.setSize(64)
        self.iconView.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.iconView)
        
        self.messageLabel.font = self.theme.fonts.primary(style: .body)
        self.messageLabel.textColor = self.theme.colors.label
        self.messageLabel.backgroundColor = self.theme.colors.background
        self.messageLabel.numberOfLines = 0
        self.addArrangedSubview(self.messageLabel)
    }
    
}
