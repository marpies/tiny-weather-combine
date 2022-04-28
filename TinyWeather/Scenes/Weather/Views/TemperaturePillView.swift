//
//  TemperaturePillView.swift
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

class TemperaturePillView: UIView {
    
    private let label: UILabel = UILabel()
    
    private var color: UIColor?
    
    var theme: Theme? {
        didSet {
            guard let theme = self.theme else { return }
            
            self.label.font = theme.fonts.primaryBold(style: .caption1)
        }
    }

    init() {
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.bounds.height / 2
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            self.layer.borderColor = self.color?.cgColor
        }
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Weather.Temperature.ViewModel) {
        self.color = viewModel.color
        self.backgroundColor = self.color?.withAlphaComponent(0.05)
        self.layer.borderColor = self.color?.cgColor
        self.label.textColor = self.color
        self.label.text = viewModel.title
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.layer.borderWidth = 1
        
        self.label.textAlignment = .center
        self.addSubview(self.label)
        self.label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(4)
        }
    }

}
