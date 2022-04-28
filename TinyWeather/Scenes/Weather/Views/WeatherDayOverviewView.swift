//
//  WeatherDayOverviewView.swift
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
import TWModels

class WeatherDayOverviewView: UIStackView {

    private var iconLabel: DuotoneLabel?
    private let minView: TemperaturePillView = TemperaturePillView()
    private let maxView: TemperaturePillView = TemperaturePillView()
    
    var theme: Theme? {
        didSet {
            guard let theme = self.theme else { return }
            
            if self.iconLabel == nil {
                self.initViews(theme: theme)
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(conditionIcon: DuotoneIcon.ViewModel, tempMin: Weather.Temperature.ViewModel, tempMax: Weather.Temperature.ViewModel) {
        self.iconLabel?.updateIcon(viewModel: conditionIcon)
        self.minView.update(viewModel: tempMin)
        self.maxView.update(viewModel: tempMax)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.axis = .horizontal
        self.spacing = 8
        self.alignment = .center
    }
    
    private func initViews(theme: Theme) {
        self.iconLabel = DuotoneLabel(theme: theme)
        self.iconLabel.map { label in
            label.setStyle(.title1)
            self.addArrangedSubview(label)
        }
        
        // Pills
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        self.addArrangedSubview(stack)
        
        self.maxView.theme = theme
        stack.addArrangedSubview(self.maxView)
        
        // fixme: temporary min width until we handle dynamic type
        self.maxView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
        
        self.minView.theme = theme
        stack.addArrangedSubview(self.minView)
        
        // fixme: temporary min width until we handle dynamic type
        self.minView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
    }

}
