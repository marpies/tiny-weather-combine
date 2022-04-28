//
//  SearchHintLocationView.swift
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

class SearchHintLocationView: UIButton {
    
    private let theme: Theme
    
    private let flagView: UIImageView = UIImageView()
    private let headerLabel: UILabel = UILabel()
    private let subheaderLabel: UILabel = UILabel()
    
    init(theme: Theme) {
        self.theme = theme
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard (oldValue && !self.isHighlighted) || (!oldValue && self.isHighlighted) else { return }
            
            let alpha: CGFloat = self.isHighlighted ? 0.5 : 1
            
            UIView.animate(withDuration: 0.3) {
                self.flagView.alpha = alpha
                self.headerLabel.alpha = alpha
                self.subheaderLabel.alpha = alpha
            }
        }
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Search.Location.ViewModel) {
        self.flagView.image = viewModel.flag
        self.headerLabel.text = viewModel.title
        self.subheaderLabel.text = viewModel.subtitle
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.flagView.isUserInteractionEnabled = false
        self.flagView.contentMode = .scaleAspectFit
        self.addSubview(self.flagView)
        self.flagView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.top.leading.bottom.equalToSuperview()
        }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        self.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(self.flagView.snp.trailing).offset(16)
        }
        
        self.headerLabel.font = self.theme.fonts.primary(style: .headline)
        self.headerLabel.textColor = self.theme.colors.label
        stack.addArrangedSubview(self.headerLabel)
        
        self.subheaderLabel.font = self.theme.fonts.primary(style: .subheadline)
        self.subheaderLabel.textColor = self.theme.colors.secondaryLabel
        stack.addArrangedSubview(self.subheaderLabel)
    }

}
