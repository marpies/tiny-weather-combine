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
import RxSwift
import RxCocoa
import RxGesture

class SearchViewController: UIViewController, UIScrollViewDelegate {
    
    private let viewModel: SearchViewModelProtocol
    private let locationBtn: UIDuotoneIconButton
    private let favoritesView: FavoriteLocationsView
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()
    private let searchField: SearchTextField = SearchTextField()
    private let visualView: UIVisualEffectView = UIVisualEffectView(effect: nil)
    
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
        
        self.viewModel.inputs.viewDidDisappear.accept(())
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
                .bind(to: self.viewModel.inputs.locationHintTap)
                .disposed(by: self.disposeBag)
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
        let pan = self.view.rx.panGesture(configuration: { [weak self] (_, delegate) in
            delegate.otherFailureRequirementPolicy = .custom({ (gesture, other) in
                // Avoid conflict with the favorites table view panning
                if let g = self?.favoritesView.panGesture {
                    return other === g || other.view === self?.favoritesView.tableView
                }
                return false
            })
        }).share()
        
        pan
            .when(.began)
            .subscribe(onNext: { [weak self] _ in
                self?.startScrubbingAnimation()
            })
            .disposed(by: self.disposeBag)
        
        pan
            .when(.changed)
            .asTranslation()
            .map({ (translation, _) in translation })
            .subscribe(onNext: { [weak self] translation in
                self?.updateAnimationProgress(translation: translation)
            })
            .disposed(by: self.disposeBag)
        
        pan
            .when(.ended)
            .asTranslation()
            .map({ (_, velocity) in velocity })
            .subscribe(onNext: { [weak self] velocity in
                self?.finishAnimation(velocity: velocity)
            })
            .disposed(by: self.disposeBag)
    }

    //
    // MARK: - View model bindable
    //

    private func bindViewModel() {
        let inputs: SearchViewModelInputs = self.viewModel.inputs
        let outputs: SearchViewModelOutputs = self.viewModel.outputs
        
        outputs.searchPlaceholder
            .compactMap({ $0 })
            .drive(self.searchField.rx.attributedPlaceholder)
            .disposed(by: self.disposeBag)
        
        outputs.searchHints
            .drive(self.searchHints)
            .disposed(by: self.disposeBag)
        
        outputs.searchHints
            .map({ $0 != nil })
            .drive(self.locationBtn.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        outputs.locationButtonTitle
            .drive(self.locationBtn.rx.viewModel)
            .disposed(by: self.disposeBag)
        
        self.searchField.rx.text
            .bind(to: inputs.searchValue)
            .disposed(by: self.disposeBag)
        
        self.searchField.rx
            .controlEvent(.editingChanged)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .bind(to: inputs.performSearch)
            .disposed(by: self.disposeBag)
        
        let editBegin = self.searchField.rx.controlEvent(.editingDidBegin)
        let editEnd = self.searchField.rx.controlEvent(.editingDidEnd)
        let editEndExit = self.searchField.rx.controlEvent(.editingDidEndOnExit)
        
        let editEvents = Observable.merge([editBegin.asObservable(), editEnd.asObservable(), editEndExit.asObservable()]).share()
        
        let disposable: Disposable = editEvents
            .subscribe(onNext: { [weak self] in
                self?.setupConstraints()
                
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self?.view.layoutIfNeeded()
                }, completion: nil)
            })
        
        // Dispose search field edit observers when the scene is about to disappear to avoid
        // modifying constraints during UINavigationController transition
        // The constraints are not animated during that and results in jumpy UI
        outputs.sceneWillHide
            .filter({ [weak self] in
                self?.searchField.isFirstResponder ?? false
            })
            .subscribe(onNext: {
                disposable.dispose()
            })
            .disposed(by: self.disposeBag)
        
        outputs.favorites
            .drive(self.favoritesView.rx.viewModel)
            .disposed(by: self.disposeBag)
        
        outputs.favoriteDeleteAlert
            .emit(to: self.rx.alert)
            .disposed(by: self.disposeBag)
        
        editBegin
            .bind(to: inputs.searchFieldDidBeginEditing)
            .disposed(by: self.disposeBag)
        
        self.animation?.animationDidComplete
            .map({ $0 == .end })
            .bind(to: inputs.animationDidComplete)
            .disposed(by: self.disposeBag)
        
        self.locationBtn.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.searchField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
        
        self.locationBtn.rx.tap
            .bind(to: inputs.searchByLocation)
            .disposed(by: self.disposeBag)
        
        self.favoritesView.tableViewDidScroll
            .filter({ [weak self] in
                self?.searchField.isFirstResponder ?? false
            })
            .subscribe(onNext: { [weak self] in
                self?.searchField.resignFirstResponder()
            })
            .disposed(by: self.disposeBag)
        
        self.favoritesView.locationDidSelect
            .bind(to: inputs.favoriteLocationDidSelect)
            .disposed(by: self.disposeBag)
        
        self.favoritesView.locationDidDelete
            .bind(to: inputs.favoriteLocationDidDelete)
            .disposed(by: self.disposeBag)
        
        outputs.sceneDidAppear
            .take(1)
            .map({ true })
            .bind(to: self.view.rx.isUserInteractionEnabled)
            .disposed(by: self.disposeBag)
        
        // Enable panning animation only when needed
        guard outputs.isInteractiveAnimationEnabled else { return }
        
        outputs.sceneDidAppear
            .take(1)
            .subscribe(onNext: { [weak self] in
                self?.registerPanGesture()
            })
            .disposed(by: self.disposeBag)
    }
    
    //
    // MARK: - Scroll view delegate
    //
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchField.isFirstResponder {
            self.searchField.endEditing(true)
        }
    }
    
}
