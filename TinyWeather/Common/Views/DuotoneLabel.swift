//
//  DuotoneLabel.swift
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

public class DuotoneLabel: UIView {
    
    private let theme: Theme
    private let primaryLabel = UILabel()
    private let secondaryLabel = UILabel()
    
    public init(theme: Theme) {
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
    
    public func updateIcon(viewModel: DuotoneIcon.ViewModel) {
        self.setIcon(viewModel.icon)
        
        if viewModel.isUnicolor {
            self.setColor(viewModel.primaryColor)
        } else {
            self.setColors(primary: viewModel.primaryColor, secondary: viewModel.secondaryColor)
        }
    }
    
    public func setIcon(_ icon: FontIcon) {
        self.primaryLabel.text = icon.primary
        self.secondaryLabel.text = icon.secondary
    }
    
    public func setIconCode(_ value: UInt32) {
        let primary: UnicodeScalar = UnicodeScalar(value)!
        let secondary: UnicodeScalar = UnicodeScalar(0x100000 | value)!
        self.primaryLabel.text = primary.escaped(asASCII: false)
        self.secondaryLabel.text = secondary.escaped(asASCII: false)
    }
    
    public func setColors(primary: UIColor, secondary: UIColor) {
        self.primaryLabel.textColor = primary
        self.secondaryLabel.textColor = secondary
    }
    
    public func setColor(_ color: UIColor) {
        self.primaryLabel.textColor = color
        self.secondaryLabel.textColor = color.withAlphaComponent(0.5)
    }
    
    public func setStyle(_ style: UIFont.TextStyle) {
        self.primaryLabel.font = self.theme.fonts.iconDuotone(style: style)
        self.secondaryLabel.font = self.theme.fonts.iconDuotone(style: style)
    }
    
    public func setSize(_ size: CGFloat) {
        self.primaryLabel.font = self.theme.fonts.iconDuotone(size: size)
        self.secondaryLabel.font = self.theme.fonts.iconDuotone(size: size)
    }
    
    public func setTextAlignment(_ alignment: NSTextAlignment) {
        self.primaryLabel.textAlignment = alignment
        self.secondaryLabel.textAlignment = alignment
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            // Primary label cannot have background color
            self.secondaryLabel.backgroundColor = self.backgroundColor
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.addSubview(self.secondaryLabel)
        self.secondaryLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(self.primaryLabel)
        self.primaryLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
}
