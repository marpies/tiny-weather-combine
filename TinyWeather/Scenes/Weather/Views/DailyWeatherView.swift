//
//  DailyWeatherView.swift
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
import SnapKit

class DailyWeatherView: UIView {
    
    private let theme: Theme
    private let contentStack: UIStackView = UIStackView()
    private var numViews: TimeInterval = 0

    init(theme: Theme) {
        self.theme = theme
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func add(viewModel: Weather.Day.ViewModel) {
        let view: WeatherDayView = WeatherDayView()
        view.alpha = 0
        view.theme = self.theme
        view.update(viewModel: viewModel)
        
        if self.contentStack.arrangedSubviews.isEmpty == false {
            let border: UIView = UIView()
            border.backgroundColor = self.theme.colors.separator
            self.contentStack.addArrangedSubview(border)
            border.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
        
        let delay: TimeInterval = self.numViews * 0.1
        
        UIView.animate(withDuration: 0.6, delay: delay, options: .curveEaseOut, animations: {
            view.alpha = 1
        }, completion: nil)
        
        self.contentStack.addArrangedSubview(view)
        
        self.numViews += 1
    }
    
    func removeAll() {
        self.numViews = 0
        
        for view in self.contentStack.arrangedSubviews {
            view.removeFromSuperview()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.contentStack.axis = .vertical
        self.contentStack.spacing = 4
        self.addSubview(self.contentStack)
        self.contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

}
