//
//  SearchViewController.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import UIKit
import Combine
import CombineCocoa

class SearchViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    private let viewModel: SearchViewModelProtocol
    private let locationBtn: UIDuotoneIconButton
    private let favoritesView: FavoriteLocationsView
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()
    private let searchField: SearchTextField = SearchTextField()
    private let visualView: UIVisualEffectView = UIVisualEffectView(effect: nil)
    
    private var panGesture: UIPanGestureRecognizer?
    private var searchHintsView: SearchHintsView?
    private var animation: SearchPanAnimation?
    
    private var animationState: Search.AnimationState {
        return self.viewModel.outputs.animationState
    }
    
    private var searchHints: Binder<Search.SearchHints?> {
        return Binder(self) { [weak self] (vc, vm) in
            if let vm = vm {
                self?.addHintsView(viewModel: vm)
            } else {
                self?.removeHintsView()
            }
        }
    }

    init(viewModel: SearchViewModelProtocol) {
        self.viewModel = viewModel
        self.locationBtn = UIDuotoneIconButton(theme: viewModel.theme)
        self.favoritesView = FavoriteLocationsView(theme: viewModel.theme)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()
        self.setupConstraints()
        self.bindViewModel()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.setupConstraints()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.viewModel.inputs.viewDidDisappear.send(())
    }
    
    //
    // MARK: - Public
    //
    
    func animateIn() {
        self.loadViewIfNeeded()
        
        self.animation?.animateIn()
    }
    
    func animateOut() {
        self.animation?.animateOut()
    }
    
    func startScrubbingAnimation() {
        self.loadViewIfNeeded()
        
        self.animation?.startInteractive(to: self.animationState.opposite)
    }
    
    func updateAnimationProgress(translation: CGPoint) {
        self.animation?.updateAnimationProgress(translation: translation)
    }
    
    func finishAnimation(velocity: CGPoint) {
        self.animation?.finishAnimation(velocity: velocity)
    }
    
    //
    // MARK: - Private
    //
    
    private func setupViews() {
        self.view.backgroundColor = .clear
        self.view.isUserInteractionEnabled = false
        
        // Blur
        self.view.addSubview(self.visualView)
        self.visualView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Scroll view
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.contentInsetAdjustmentBehavior = .always
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.width.equalTo(self.view)
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalTo(self.scrollView)
        }
        
        // Favorites view
        self.favoritesView.alpha = 0
        self.contentView.addSubview(self.favoritesView)
        
        // Location button
        self.locationBtn.alpha = 0
        self.locationBtn.setContentCompressionResistancePriority(.required, for: .vertical)
        self.contentView.addSubview(self.locationBtn)
        
        // Search field
        self.searchField.update(for: self.viewModel.theme)
        self.searchField.alpha = 0
        self.searchField.keyboardType = .alphabet
        self.searchField.textContentType = .addressCityAndState
        self.searchField.returnKeyType = .done
        self.searchField.autocorrectionType = .no
        self.searchField.transform = CGAffineTransform(scaleX: 0.6, y: 0.6).translatedBy(x: 0, y: -50)
        self.searchField.setContentCompressionResistancePriority(.required, for: .vertical)
        self.contentView.addSubview(self.searchField)
        
        // Animation
        self.animation = SearchPanAnimation(searchField: self.searchField, visualView: self.visualView, locationBtn: self.locationBtn, favoritesView: self.favoritesView)
    }
    
    private func setupConstraints() {
        let isRegular: Bool = self.traitCollection.horizontalSizeClass == .regular
        
        self.searchField.snp.remakeConstraints { make in
            if isRegular {
                make.width.equalToSuperview().multipliedBy(0.5)
            } else {
                make.width.equalToSuperview().inset(24)
            }
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.contentView).offset(8)
        }
        
        self.locationBtn.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.searchField.snp.bottom).offset(16)
        }
        
        self.favoritesView.snp.makeConstraints { make in
            if isRegular {
                make.width.equalTo(self.view.readableContentGuide)
            } else {
                make.width.equalTo(self.view.layoutMarginsGuide)
            }
            make.centerX.equalToSuperview()
            make.top.equalTo(self.scrollView.safeAreaLayoutGuide.snp.centerY).multipliedBy(0.8)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    private func addHintsView(viewModel: Search.SearchHints) {
        if self.searchHintsView == nil {
            self.searchHintsView = SearchHintsView(theme: self.viewModel.theme)
            self.searchHintsView?.hintViewTap
                .assign(to: self.viewModel.inputs.locationHintTap)
                .store(in: &self.cancellables)
            self.contentView.insertSubview(self.searchHintsView!, belowSubview: self.searchField)
            self.searchHintsView?.snp.makeConstraints({ make in
                make.top.equalTo(self.searchField.snp.bottom).offset(-8)
                make.leading.trailing.equalTo(self.searchField).inset(24)
                make.bottom.lessThanOrEqualToSuperview()
            })
        }
        
        self.searchHintsView?.update(viewModel: viewModel)
        self.animation?.hintsView = self.searchHintsView
    }
    
    private func removeHintsView() {
        self.searchHintsView?.removeFromSuperview()
        self.searchHintsView = nil
        self.animation?.hintsView = nil
    }
    
    private func registerPanGesture() {
        guard self.panGesture == nil else { return }
        
        self.panGesture = UIPanGestureRecognizer(target: self.view, action: nil)
        self.panGesture?.delegate = self
        self.view.addGestureRecognizer(self.panGesture!)
        
        let pan = self.panGesture!.panPublisher.share()
        
        pan
            .filter({ $0.state == .began })
            .sink(receiveValue: { [weak self] _ in
                self?.startScrubbingAnimation()
            })
            .store(in: &self.cancellables)
        
        pan
            .filter({ $0.state == .changed })
            .map({ [weak self] gesture in
                gesture.translation(in: self?.view)
            })
            .sink(receiveValue: { [weak self] (translation) in
                self?.updateAnimationProgress(translation: translation)
            })
            .store(in: &self.cancellables)
        
        pan
            .filter({ $0.state == .ended })
            .map({ [weak self] gesture in
                gesture.velocity(in: self?.view)
            })
            .sink(receiveValue: { [weak self] (velocity) in
                self?.finishAnimation(velocity: velocity)
            })
            .store(in: &self.cancellables)
    }

    //
    // MARK: - View model bindable
    //

    private func bindViewModel() {
        let inputs: SearchViewModelInputs = self.viewModel.inputs
        let outputs: SearchViewModelOutputs = self.viewModel.outputs
        
        outputs.searchPlaceholder
            .compactMap({ $0 })
            .bind(to: self.searchField.rx.attributedPlaceholder)
            .store(in: &self.cancellables)
        
        outputs.searchHints
            .bind(to: self.searchHints)
            .store(in: &self.cancellables)
        
        outputs.searchHints
            .map({ $0 != nil })
            .bind(to: self.locationBtn.rx.isHidden)
            .store(in: &self.cancellables)
        
        outputs.locationButtonTitle
            .bind(to: self.locationBtn.rx.viewModel)
            .store(in: &self.cancellables)
        
        self.searchField.textPublisher
            .assign(to: \.value, on: inputs.searchValue)
            .store(in: &self.cancellables)
        
        self.searchField
            .controlEventPublisher(for: .editingChanged)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .assign(to: inputs.performSearch)
            .store(in: &self.cancellables)
        
        let editBegin: AnyPublisher<Void, Never> = self.searchField.controlEventPublisher(for: .editingDidBegin)
        
        outputs.favorites
            .bind(to: self.favoritesView.rx.viewModel)
            .store(in: &self.cancellables)
        
        outputs.favoriteDeleteAlert
            .bind(to: self.rx.alert)
            .store(in: &self.cancellables)
        
        editBegin
            .assign(to: inputs.searchFieldDidBeginEditing)
            .store(in: &self.cancellables)
        
        self.animation?.animationDidComplete
            .map({ $0 == .end })
            .assign(to: inputs.animationDidComplete)
            .store(in: &self.cancellables)
        
        self.locationBtn
            .tapPublisher
            .sink(receiveValue: { [weak self] in
                self?.searchField.resignFirstResponder()
            })
            .store(in: &self.cancellables)
        
        self.locationBtn
            .tapPublisher
            .assign(to: inputs.searchByLocation)
            .store(in: &self.cancellables)
        
        self.favoritesView.tableViewDidScroll
            .filter({ [weak self] in
                self?.searchField.isFirstResponder ?? false
            })
            .sink(receiveValue: { [weak self] in
                self?.searchField.resignFirstResponder()
            })
            .store(in: &self.cancellables)
        
        self.favoritesView.locationDidSelect
            .assign(to: inputs.favoriteLocationDidSelect)
            .store(in: &self.cancellables)
        
        self.favoritesView.locationDidDelete
            .assign(to: inputs.favoriteLocationDidDelete)
            .store(in: &self.cancellables)
        
        outputs.sceneDidAppear
            .prefix(1)
            .map({ true })
            .sink(receiveValue: { [weak self] _ in
                self?.view.isUserInteractionEnabled = true
            })
            .store(in: &self.cancellables)
        
        // Enable panning animation only when needed
        guard outputs.isInteractiveAnimationEnabled else { return }
        
        outputs.sceneDidAppear
            .prefix(1)
            .sink(receiveValue: { [weak self] in
                self?.registerPanGesture()
            })
            .store(in: &self.cancellables)
    }
    
    //
    // MARK: - Scroll view delegate
    //
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchField.isFirstResponder {
            self.searchField.endEditing(true)
        }
    }
    
    //
    // MARK: - Pan gesture delegate
    //
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Avoid conflict with the favorites table view panning
        if let g = self.favoritesView.panGesture {
            return otherGestureRecognizer === g || otherGestureRecognizer.view === self.favoritesView.tableView
        }
        return false
    }
    
}
