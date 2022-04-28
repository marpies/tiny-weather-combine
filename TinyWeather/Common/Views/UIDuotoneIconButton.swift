//
//  UIDuotoneIconButton.swift
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
import TWModels
import SnapKit

class UIDuotoneIconButton: UIButton {
    
    private let theme: Theme
    private let iconView: DuotoneLabel
    private let label: UILabel = UILabel()

    init(theme: Theme) {
        self.theme = theme
        self.iconView = DuotoneLabel(theme: theme)
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    override var isHighlighted: Bool {
        didSet {
            guard (self.isHighlighted && !oldValue) || (!self.isHighlighted && oldValue) else { return }
            
            let alpha: CGFloat = self.isHighlighted ? 0.5 : 1
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.iconView.alpha = alpha
                self.label.alpha = alpha
            }, completion: nil)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle {
            self.layer.borderColor = self.theme.colors.separator.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.bounds.height / 2
    }
    
    func update(viewModel: DuotoneIconButton.ViewModel) {
        self.iconView.setIcon(viewModel.icon)
        self.label.text = viewModel.title
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.layer.borderWidth = 1
        self.layer.borderColor = self.theme.colors.separator.cgColor
        self.backgroundColor = self.theme.colors.secondaryBackground.withAlphaComponent(0.5)
        
        self.titleLabel?.isHidden = true
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        self.addSubview(stack)
        
        self.iconView.setStyle(.body)
        self.iconView.setColor(self.theme.colors.label)
        stack.addArrangedSubview(self.iconView)
        
        self.label.font = self.theme.fonts.primary(style: .body)
        self.label.textColor = self.theme.colors.label
        stack.addArrangedSubview(self.label)
        
        stack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
}
