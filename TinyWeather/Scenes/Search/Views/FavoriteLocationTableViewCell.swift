//
//  FavoriteLocationTableViewCell.swift
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

class FavoriteLocationTableViewCell: UITableViewCell {
    
    private let labelsStack: UIStackView = UIStackView()
    private let titleLabel: UILabel = UILabel()
    private let subtitleLabel: UILabel = UILabel()
    private let flagView: UIImageView = UIImageView()
    
    var theme: Theme? {
        didSet {
            guard let theme = self.theme else { return }
            
            self.titleLabel.font = theme.fonts.primary(style: .headline)
            self.titleLabel.textColor = theme.colors.label
            
            self.subtitleLabel.font = theme.fonts.primary(style: .subheadline)
            self.subtitleLabel.textColor = theme.colors.secondaryLabel
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let isHighlighted: Bool = self.isHighlighted
        
        super.setHighlighted(highlighted, animated: animated)
        
        guard isHighlighted != highlighted else { return }
        
        let alpha: CGFloat = highlighted ? 0.5 : 1
        
        UIView.animate(withDuration: 0.3) {
            self.titleLabel.alpha = alpha
            self.subtitleLabel.alpha = alpha
            self.flagView.alpha = alpha
        }
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Search.Location.ViewModel) {
        self.flagView.image = viewModel.flag
        self.titleLabel.text = viewModel.title
        self.subtitleLabel.text = viewModel.subtitle
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.selectionStyle = .none
        
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        
        self.flagView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.flagView)
        self.flagView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(12)
            make.width.equalTo(self.flagView.snp.width)
        }
        
        self.labelsStack.axis = .vertical
        self.labelsStack.spacing = 4
        self.labelsStack.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        self.contentView.addSubview(self.labelsStack)
        self.labelsStack.snp.makeConstraints { make in
            make.leading.equalTo(self.flagView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        self.titleLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        self.labelsStack.addArrangedSubview(self.titleLabel)
        self.subtitleLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        self.labelsStack.addArrangedSubview(self.subtitleLabel)
    }
    
}
