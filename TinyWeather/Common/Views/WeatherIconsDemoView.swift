//
//  WeatherIconsDemoView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

#if DEBUG

import UIKit
import SnapKit
import TWThemes
import TWModels

class WeatherIconsDemoView: UIView {
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()

    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.scrollView.contentInsetAdjustmentBehavior = .never
        self.scrollView.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalTo(self)
            make.height.equalTo(self.scrollView).priority(.medium)
            make.top.bottom.equalToSuperview()
        }
        
        // Icons
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 48
        stack.alignment = .center
        self.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(32)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
            make.centerY.equalToSuperview()
        }
        
        let theme: Theme = AppTheme()
        let colors: WeatherColors = theme.colors.weather
        
        let vms: [DuotoneIcon.ViewModel] = [
            DuotoneIcon.ViewModel(icon: .thunderstormMoon, primaryColor: colors.cloud, secondaryColor: colors.moon),
            DuotoneIcon.ViewModel(icon: .thunderstorm, primaryColor: colors.cloud, secondaryColor: colors.bolt),
            DuotoneIcon.ViewModel(icon: .cloudDrizzle, primaryColor: colors.cloud, secondaryColor: colors.rain),
            DuotoneIcon.ViewModel(icon: .cloudMoonRain, primaryColor: colors.cloud, secondaryColor: colors.moon),
            DuotoneIcon.ViewModel(icon: .cloudRain, primaryColor: colors.cloud, secondaryColor: colors.rain),
            DuotoneIcon.ViewModel(icon: .cloudShowers, primaryColor: colors.cloud, secondaryColor: colors.rain),
            DuotoneIcon.ViewModel(icon: .cloudHailMixed, primaryColor: colors.cloud, secondaryColor: colors.snow),
            DuotoneIcon.ViewModel(icon: .snowflakes, color: colors.snow),
            DuotoneIcon.ViewModel(icon: .cloudSnow, primaryColor: colors.cloud, secondaryColor: colors.snow),
            DuotoneIcon.ViewModel(icon: .smog, primaryColor: colors.cloud, secondaryColor: colors.fog),
            DuotoneIcon.ViewModel(icon: .moonStars, primaryColor: colors.moon, secondaryColor: colors.stars),
            DuotoneIcon.ViewModel(icon: .sun, color: colors.sun),
            DuotoneIcon.ViewModel(icon: .moonCloud, primaryColor: colors.cloud, secondaryColor: colors.moon),
            DuotoneIcon.ViewModel(icon: .sunCloud, primaryColor: colors.cloud, secondaryColor: colors.sun),
            DuotoneIcon.ViewModel(icon: .cloudMoon, primaryColor: colors.cloud, secondaryColor: colors.moon),
            DuotoneIcon.ViewModel(icon: .cloudSun, primaryColor: colors.cloud, secondaryColor: colors.sun),
            DuotoneIcon.ViewModel(icon: .cloudsMoon, primaryColor: colors.cloud, secondaryColor: colors.moon),
            DuotoneIcon.ViewModel(icon: .clouds, color: colors.cloud)
        ]
        
        var i = 0
        while i < vms.count {
            let hstack = UIStackView()
            hstack.axis = .horizontal
            hstack.alignment = .top
            hstack.spacing = 32
            stack.addArrangedSubview(hstack)
            
            for n in 0..<3 {
                let icon = DuotoneLabel(theme: theme)
                icon.updateIcon(viewModel: vms[i + n])
                icon.setSize(66)
                hstack.addArrangedSubview(icon)
            }
            
            i += 3
        }
    }

}

#endif
