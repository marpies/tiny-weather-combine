//
//  WeatherDayView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import UIKit
import SnapKit
import TWThemes

class WeatherDayView: UIView {
    
    private let contentStack: UIStackView = UIStackView()
    private let dayOfWeekLabel: UILabel = UILabel()
    private let dateLabel: UILabel = UILabel()
    private let overviewView: WeatherDayOverviewView = WeatherDayOverviewView()
    private var attributesView: WeatherAttributesView?
    
    var theme: Theme? {
        didSet {
            guard let theme = self.theme else { return }
            
            self.backgroundColor = theme.colors.background
            
            self.dayOfWeekLabel.font = theme.fonts.primary(style: .title2)
            self.dayOfWeekLabel.textColor = theme.colors.label
            self.dayOfWeekLabel.backgroundColor = theme.colors.background
            
            self.dateLabel.font = theme.fonts.primary(style: .subheadline)
            self.dateLabel.textColor = theme.colors.secondaryLabel
            self.dateLabel.backgroundColor = theme.colors.background
            
            self.overviewView.theme = theme
            
            if self.attributesView == nil {
                self.setupAttributesView(theme: theme)
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Weather.Day.ViewModel) {
        self.dayOfWeekLabel.text = viewModel.dayOfWeek
        self.dateLabel.text = viewModel.date
        self.overviewView.update(conditionIcon: viewModel.conditionIcon, tempMin: viewModel.tempMin, tempMax: viewModel.tempMax)
        self.attributesView?.update(viewModel: viewModel.attributes)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.contentStack.axis = .horizontal
        self.contentStack.alignment = .center
        self.addSubview(self.contentStack)
        self.contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
        }
        
        // Day of week + date
        let dateStack = UIStackView()
        dateStack.axis = .vertical
        dateStack.alignment = .leading
        self.contentStack.addArrangedSubview(dateStack)
        
        dateStack.addArrangedSubview(self.dayOfWeekLabel)
        dateStack.addArrangedSubview(self.dateLabel)
        dateStack.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        
        // Day overview
        self.overviewView.setContentHuggingPriority(.defaultLow - 2, for: .horizontal)
        self.contentStack.addArrangedSubview(self.overviewView)
    }
    
    private func setupAttributesView(theme: Theme) {
        self.attributesView = WeatherAttributesView(theme: theme, style: .small)
        self.attributesView.map { view in
            self.contentStack.insertArrangedSubview(view, at: 1)
        }
    }
    
}
