//
//  SearchTextField.swift
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

class SearchTextField: UITextField {
    
    private let horizontalPadding: CGFloat = 16

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius: CGFloat = self.bounds.height / 2
        self.layer.cornerRadius = radius
        self.layer.shadowPath = CGPath(roundedRect: self.bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.minX + self.horizontalPadding, y: bounds.minY, width: bounds.width - (self.horizontalPadding * 2), height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
    
    func update(for theme: Theme) {
        self.font = theme.fonts.primary(style: .title2)
        self.textColor = theme.colors.label
        self.backgroundColor = theme.colors.secondaryBackground
        self.layer.shadowColor = theme.colors.shadow.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = 0.15
    }

}
