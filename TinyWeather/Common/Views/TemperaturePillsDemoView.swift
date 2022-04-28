//
//  TemperaturePillsDemoView.swift
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

class TemperaturePillsDemoView: UIView, TemperaturePresenting {
    
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
        stack.spacing = 16
        stack.alignment = .center
        self.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(32)
            make.bottom.lessThanOrEqualToSuperview().inset(32)
            make.centerY.equalToSuperview()
        }
        
        let theme: Theme = AppTheme()
        
        let temps: [Float] = Array(stride(from: -30, through: 41, by: 1).reversed())
        let vms: [Weather.Temperature.ViewModel] = temps.map { self.getTemperature($0, theme: theme) }
        
        var i = 0
        let columns: Int = 6
        while i < vms.count {
            let hstack = UIStackView()
            hstack.axis = .horizontal
            hstack.spacing = 8
            stack.addArrangedSubview(hstack)
            
            for n in 0..<columns {
                let k = i + n
                
                guard k < vms.count else { return }
                
                let view = TemperaturePillView()
                view.theme = theme
                view.update(viewModel: vms[i + n])
                hstack.addArrangedSubview(view)
                view.snp.makeConstraints { make in
                    make.width.greaterThanOrEqualTo(40)
                }
            }
            
            i += columns
        }
    }
    
}

#endif
