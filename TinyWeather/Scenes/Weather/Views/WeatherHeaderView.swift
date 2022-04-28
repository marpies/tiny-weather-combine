//
//  WeatherHeaderView.swift
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
import TWExtensions

class WeatherHeaderView: UIView {

    private let theme: Theme
    private let stackView: UIStackView = UIStackView()
    private let borderView: UIView = UIView()
    private var locationView: WeatherLocationView?
    private var currentWeatherView: CurrentWeatherView?
    private var spinnerView: UIActivityIndicatorView?

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
    
    func updateLocation(viewModel: Weather.Location.ViewModel) {
        if self.locationView == nil {
            self.locationView = WeatherLocationView(theme: self.theme)
            self.stackView.insertArrangedSubview(self.locationView!, at: 0)
            self.locationView?.snp.makeConstraints({ make in
                make.width.equalToSuperview()
            })
            
            self.locationView?.fadeIn()
        }
        
        self.locationView?.update(viewModel: viewModel)
    }
    
    func updateWeather(viewModel: Weather.Current.ViewModel) {
        if self.currentWeatherView == nil {
            self.currentWeatherView = CurrentWeatherView(theme: self.theme)
            self.stackView.addArrangedSubview(self.currentWeatherView!)
            self.currentWeatherView?.snp.makeConstraints({ make in
                make.width.equalToSuperview()
            })
            
            self.currentWeatherView?.fadeIn()
        }
        
        self.currentWeatherView?.update(viewModel: viewModel)
    }
    
    func showLoading() {
        if self.spinnerView == nil {
            self.spinnerView = UIActivityIndicatorView()
        }
        
        self.currentWeatherView?.removeFromSuperview()
        self.currentWeatherView = nil
        
        self.spinnerView?.startAnimating()
        self.stackView.addArrangedSubview(self.spinnerView!)
    }
    
    func hideLoading() {
        self.spinnerView?.stopAnimating()
        self.spinnerView?.removeFromSuperview()
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.layoutMargins = UIEdgeInsets(top: 16, left: 24, bottom: 28, right: 16)
        
        self.stackView.axis = .vertical
        self.stackView.spacing = 32
        self.stackView.alignment = .center
        self.addSubview(self.stackView)
        self.stackView.snp.makeConstraints { make in
            make.top.equalTo(self.layoutMarginsGuide).priority(.high)
            make.leading.trailing.equalToSuperview().priority(.high)
            make.bottom.equalTo(self.layoutMarginsGuide).priority(.high)
        }
        
        self.borderView.backgroundColor = self.theme.colors.separator
    }

}
