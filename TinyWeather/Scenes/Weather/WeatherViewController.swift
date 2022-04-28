//
//  WeatherViewController.swift
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
import SnapKit

class WeatherViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate {
    
    private let viewModel: WeatherViewModelProtocol
    private let disposeBag: DisposeBag = DisposeBag()
    
    private let headerView: WeatherHeaderView
    private let dailyWeatherView: DailyWeatherView
    private let favoriteBtn: UIIconButton
    
    private let contentView: UIView = UIView()
    private let scrollView: UIScrollView = UIScrollView()
    
    private var errorView: WeatherErrorView?
    
    private var errorViewModel: Binder<Weather.Error.ViewModel?> {
        return Binder(self) { [weak self] (vc, vm) in
            if let vm = vm {
                self?.addErrorView(viewModel: vm)
            } else {
                self?.removeErrorView()
            }
        }
    }
    
    init(viewModel: WeatherViewModelProtocol) {
        self.viewModel = viewModel
        self.headerView = WeatherHeaderView(theme: viewModel.theme)
        self.dailyWeatherView = DailyWeatherView(theme: viewModel.theme)
        self.favoriteBtn = UIIconButton(theme: viewModel.theme)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = self.viewModel.theme.colors.background
        
        self.setupViews()
        self.bindViewModel()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.horizontalSizeClass != self.traitCollection.horizontalSizeClass {
            self.layoutSubviews()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func setupViews() {
        self.scrollView.backgroundColor = self.viewModel.theme.colors.background
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.contentView.backgroundColor = self.viewModel.theme.colors.background
        self.scrollView.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self.view)
            make.height.equalTo(self.scrollView.safeAreaLayoutGuide).priority(.medium)
        }
        
        self.headerView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.contentView.addSubview(self.headerView)
        
        self.dailyWeatherView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.contentView.addSubview(self.dailyWeatherView)
        
        self.favoriteBtn.setContentCompressionResistancePriority(.required, for: .vertical)
        self.contentView.addSubview(self.favoriteBtn)
        
        self.layoutSubviews()
    }
    
    private func layoutSubviews() {
        let isRegular: Bool = self.traitCollection.horizontalSizeClass == .regular
        
        if isRegular {
            self.layoutRegularViews()
        } else {
            self.layoutCompactViews()
        }
    }
    
    private func layoutRegularViews() {
        self.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        self.headerView.snp.remakeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.centerY.equalToSuperview().multipliedBy(0.94)
        }
        
        self.favoriteBtn.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.top.equalTo(self.headerView.snp.bottom)
        }
        
        self.dailyWeatherView.snp.remakeConstraints { make in
            make.leading.equalTo(self.contentView.snp.centerX)
            make.trailing.equalTo(self.contentView.layoutMarginsGuide)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        self.errorView?.snp.remakeConstraints({ make in
            make.leading.equalTo(self.contentView.snp.centerX)
            make.trailing.equalTo(self.contentView.layoutMarginsGuide)
            make.centerY.equalToSuperview()
        })
    }
    
    private func layoutCompactViews() {
        self.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        self.headerView.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(self.contentView.layoutMarginsGuide)
            make.top.equalToSuperview()
        }
        
        self.favoriteBtn.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.headerView.snp.bottom)
        }
        
        self.dailyWeatherView.snp.remakeConstraints { make in
            make.top.equalTo(self.favoriteBtn.snp.bottom).offset(16)
            make.leading.trailing.equalTo(self.contentView.layoutMarginsGuide)
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        self.errorView?.snp.remakeConstraints({ make in
            make.top.equalTo(self.headerView.snp.bottom).offset(16)
            make.leading.trailing.equalTo(self.contentView.layoutMarginsGuide)
            make.bottom.lessThanOrEqualToSuperview()
        })
    }
    
    private func addErrorView(viewModel: Weather.Error.ViewModel) {
        if self.errorView == nil {
            self.errorView = WeatherErrorView(theme: self.viewModel.theme)
            self.contentView.addSubview(self.errorView!)
        }
        
        self.errorView?.update(viewModel: viewModel)
        self.layoutSubviews()
    }
    
    private func removeErrorView() {
        if let view = self.errorView {
            self.errorView = nil
            view.removeFromSuperview()
        }
    }

    //
    // MARK: - View model bindable
    //

    private func bindViewModel() {
        let inputs: WeatherViewModelInputs = self.viewModel.inputs
        let outputs: WeatherViewModelOutputs = self.viewModel.outputs
        
        outputs.locationInfo
            .drive(self.headerView.rx.location)
            .disposed(by: self.disposeBag)
        
        outputs.currentWeather
            .drive(self.headerView.rx.weather)
            .disposed(by: self.disposeBag)
        
        outputs.newDailyWeather
            .drive(self.dailyWeatherView.rx.newDailyWeather)
            .disposed(by: self.disposeBag)
        
        outputs.state
            .filter({ $0 == .loading })
            .map({ _ in })
            .drive(self.headerView.rx.showLoading)
            .disposed(by: self.disposeBag)
        
        outputs.dailyWeatherWillRefresh
            .drive(self.dailyWeatherView.rx.removeAll)
            .disposed(by: self.disposeBag)
        
        outputs.state
            .map({ $0 != .loaded })
            .drive(self.dailyWeatherView.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        outputs.state
            .filter({ $0 != .loading })
            .map({ _ in })
            .drive(self.headerView.rx.hideLoading)
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(outputs.state.asObservable(), outputs.favoriteButtonTitle.asObservable())
            .map({ (state, title) -> Bool in
                (title == nil) || (state != .loaded)
            })
            .bind(to: self.favoriteBtn.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        outputs.favoriteButtonTitle
            .compactMap({ $0 })
            .drive(self.favoriteBtn.rx.viewModel)
            .disposed(by: self.disposeBag)
        
        outputs.favoriteStatusAlert
            .emit(to: self.rx.alert)
            .disposed(by: self.disposeBag)
        
        outputs.weatherError
            .drive(self.errorViewModel)
            .disposed(by: self.disposeBag)
        
        self.favoriteBtn.rx
            .tap
            .bind(to: inputs.toggleFavoriteStatus)
            .disposed(by: self.disposeBag)
        
        self.scrollView.rx
            .willBeginDragging
            .bind(to: inputs.panGestureDidBegin)
            .disposed(by: self.disposeBag)
        
        self.scrollView.rx
            .didScroll
            .compactMap({ [weak self] () -> CGFloat? in
                guard let weakSelf = self else { return nil }
                
                return -(weakSelf.view.safeAreaInsets.top + weakSelf.scrollView.contentOffset.y)
            })
            .bind(to: inputs.panGestureDidChange)
            .disposed(by: self.disposeBag)
        
        self.scrollView.rx
            .willEndDragging
            .compactMap({ [weak self] _ -> CGPoint? in
                self?.scrollView.panGestureRecognizer.velocity(in: self?.view)
            })
            .bind(to: inputs.panGestureDidEnd)
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map({ _ in })
            .bind(to: inputs.appDidEnterBackground)
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .map({ _ in })
            .bind(to: inputs.appDidBecomeActive)
            .disposed(by: self.disposeBag)
    }
    
}
