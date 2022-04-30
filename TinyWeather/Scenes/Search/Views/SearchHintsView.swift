//
//  SearchHintsView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import UIKit
import SnapKit
import Combine
import TWThemes

class SearchHintsView: UIView {
    
    private let theme: Theme
    private var cancellables: Set<AnyCancellable> = []
    
    // Outputs
    private let _hintViewTap: PassthroughSubject<Int, Never> = PassthroughSubject()
    let hintViewTap: AnyPublisher<Int, Never>
    
    init(theme: Theme) {
        self.theme = theme
        self.hintViewTap = _hintViewTap.eraseToAnyPublisher()
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Search.SearchHints) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        switch viewModel {
        case .loading:
            self.addLoading()
        
        case .empty(let message), .error(let message):
            self.addLabel(message: message)
            
        case .results(let cities):
            self.addCities(cities)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupView() {
        self.backgroundColor = self.theme.colors.secondaryBackground.withAlphaComponent(0.9)
        self.layer.cornerRadius = 8
        self.layer.shadowColor = self.theme.colors.shadow.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = 0.15
    }
    
    private func addLabel(message: String) {
        let label = UILabel()
        label.font = self.theme.fonts.primary(style: .body)
        label.textColor = self.theme.colors.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = message
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func addCities(_ locations: [Search.Location.ViewModel]) {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.isUserInteractionEnabled = true
        self.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().inset(16)
        }
        
        for (index, viewModel) in locations.enumerated() {
            let view: SearchHintLocationView = SearchHintLocationView(theme: self.theme)
            view.tag = index
            view.update(viewModel: viewModel)
            view.tapPublisher
                .map({ view.tag })
                .assign(to: self._hintViewTap)
                .store(in: &self.cancellables)
            stack.addArrangedSubview(view)
        }
    }
    
    private func addLoading() {
        let spinner: UIActivityIndicatorView = UIActivityIndicatorView()
        spinner.startAnimating()
        self.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }
    }
    
}
