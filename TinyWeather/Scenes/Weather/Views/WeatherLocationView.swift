//
//  WeatherLocationView.swift
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

class WeatherLocationView: UIStackView {
    
    private let theme: Theme
    
    private let titleLabel: UILabel = UILabel()
    private let subtitleLabel: UILabel = UILabel()
    private let flagView: UIImageView = UIImageView()
    
    init(theme: Theme) {
        self.theme = theme
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Weather.Location.ViewModel) {
        self.titleLabel.text = viewModel.title
        self.subtitleLabel.text = viewModel.subtitle
        self.flagView.image = viewModel.flag
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .vertical
        self.alignment = .center
        
        // Title + flag
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        self.addArrangedSubview(stack)
        
        self.titleLabel.font = self.theme.fonts.primary(style: .title1)
        self.titleLabel.textColor = self.theme.colors.label
        self.titleLabel.backgroundColor = self.theme.colors.background
        stack.addArrangedSubview(self.titleLabel)
        
        self.flagView.backgroundColor = self.theme.colors.background
        self.flagView.contentMode = .scaleAspectFit
        stack.addArrangedSubview(self.flagView)
        self.flagView.snp.makeConstraints { make in
            make.size.equalTo(24)
        }
        
        // Subtitle
        self.subtitleLabel.font = self.theme.fonts.primary(style: .subheadline)
        self.subtitleLabel.textColor = self.theme.colors.secondaryLabel
        self.subtitleLabel.backgroundColor = self.theme.colors.background
        self.addArrangedSubview(self.subtitleLabel)
    }
    
}
