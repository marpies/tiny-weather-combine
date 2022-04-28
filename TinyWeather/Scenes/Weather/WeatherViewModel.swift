//
//  WeatherViewModel.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import TWThemes
import TWExtensions
import TWModels
import TWRoutes
import Combine

protocol WeatherViewModelInputs {
    var panGestureDidBegin: PublishRelay<Void> { get }
    var panGestureDidChange: PublishRelay<CGFloat> { get }
    var panGestureDidEnd: PublishRelay<CGPoint> { get }
    var toggleFavoriteStatus: PublishRelay<Void> { get }
    var appDidEnterBackground: PublishRelay<Void> { get }
    var appDidBecomeActive: PublishRelay<Void> { get }
}

protocol WeatherViewModelOutputs {
    var locationInfo: Driver<Weather.Location.ViewModel> { get }
    var state: Driver<Weather.State> { get }
    var currentWeather: Driver<Weather.Current.ViewModel> { get }
    var dailyWeatherWillRefresh: Driver<Void> { get }
    var newDailyWeather: Driver<Weather.Day.ViewModel> { get }
    var favoriteButtonTitle: Driver<IconButton.ViewModel?> { get }
    var favoriteStatusAlert: Signal<Alert.ViewModel> { get }
    var weatherError: Driver<Weather.Error.ViewModel?> { get }
}

protocol WeatherViewModelProtocol {
    var theme: Theme { get }
    var inputs: WeatherViewModelInputs { get }
    var outputs: WeatherViewModelOutputs { get }
    
    func loadWeather(forLocation location: WeatherLocation)
    func favoriteDidDelete(forLocation location: WeatherLocation)
}

class WeatherViewModel: WeatherViewModelProtocol, WeatherViewModelInputs, WeatherViewModelOutputs, WeatherConditionPresenting, TemperaturePresenting, WindSpeedPresenting,
                        RainAmountPresenting, SnowAmountPresenting {
    
    private var cancellables: Set<AnyCancellable> = []
    private let disposeBag: DisposeBag = DisposeBag()
    private let dateFormatter: DateFormatter = DateFormatter()
    
    private let weatherLoader: WeatherLoading
    private let router: WeakRouter<AppRoute>
    private let storage: WeatherStorageManaging
    
    private var model: Weather.Model = Weather.Model()
    
    private var didBeginPan: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private var panTranslation: BehaviorRelay<CGFloat> = BehaviorRelay(value: 0)
    
    private var autoRefreshDisposable: Disposable?

    var inputs: WeatherViewModelInputs { return self }
    var outputs: WeatherViewModelOutputs { return self }
    
    let theme: Theme

    // Inputs
    let panGestureDidBegin: PublishRelay<Void> = PublishRelay()
    let panGestureDidChange: PublishRelay<CGFloat> = PublishRelay()
    let panGestureDidEnd: PublishRelay<CGPoint> = PublishRelay()
    let toggleFavoriteStatus: PublishRelay<Void> = PublishRelay()
    let appDidEnterBackground: PublishRelay<Void> = PublishRelay()
    let appDidBecomeActive: PublishRelay<Void> = PublishRelay()

    // Outputs
    private let _locationInfo: BehaviorRelay<Weather.Location.ViewModel?> = BehaviorRelay(value: nil)
    let locationInfo: Driver<Weather.Location.ViewModel>
    
    private let _state: BehaviorRelay<Weather.State> = BehaviorRelay(value: .loading)
    let state: Driver<Weather.State>
    
    private let _currentWeather: BehaviorRelay<Weather.Current.ViewModel?> = BehaviorRelay(value: nil)
    let currentWeather: Driver<Weather.Current.ViewModel>
    
    private let _dailyWeatherWillRefresh: PublishRelay<Void> = PublishRelay()
    let dailyWeatherWillRefresh: Driver<Void>
    
    private let _dailyWeather: BehaviorRelay<[Weather.Day.ViewModel?]?> = BehaviorRelay(value: nil)
    let newDailyWeather: Driver<Weather.Day.ViewModel>
    
    private let isLocationFavorite: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private let _favoriteButtonTitle: BehaviorRelay<IconButton.ViewModel?> = BehaviorRelay(value: nil)
    let favoriteButtonTitle: Driver<IconButton.ViewModel?>
    
    private let _favoriteStatusAlert: PublishRelay<Alert.ViewModel> = PublishRelay()
    let favoriteStatusAlert: Signal<Alert.ViewModel>
    
    private let _weatherError: PublishRelay<Weather.Error.ViewModel?> = PublishRelay()
    let weatherError: Driver<Weather.Error.ViewModel?>

    init(theme: Theme, weatherLoader: WeatherLoading, router: WeakRouter<AppRoute>, storage: WeatherStorageManaging) {
        self.theme = theme
        self.weatherLoader = weatherLoader
        self.router = router
        self.storage = storage
        
        self.dateFormatter.timeStyle = .short
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")!
        self.dateFormatter.locale = Locale.current
        
        // Outputs
        self.state = _state.asDriver()
        
        self.locationInfo = _locationInfo.asDriver().compactMap({ $0 })
        self.currentWeather = _currentWeather.asDriver().compactMap({ $0 })
        
        self.dailyWeatherWillRefresh = _dailyWeatherWillRefresh.asDriver(onErrorJustReturn: ())
        self.newDailyWeather = _dailyWeather
            .compactMap({ $0 })
            .flatMap({
                Observable.from($0)
                    .observe(on: MainScheduler.instance)
            })
            .asDriver(onErrorJustReturn: nil)
            .compactMap({ $0 })
        
        self.favoriteButtonTitle = _favoriteButtonTitle.asDriver(onErrorJustReturn: nil)
        self.favoriteStatusAlert = _favoriteStatusAlert.asSignal()
        
        self.weatherError = _weatherError.asDriver(onErrorJustReturn: nil)
        
        // Init auto-refresh timer
        self.setAutoRefreshTimer()
        
        self.panGestureDidBegin
            .map({ true })
            .bind(to: self.didBeginPan)
            .disposed(by: self.disposeBag)
        
        self.panGestureDidBegin
            .subscribe(onNext: {
                router.route(to: .search(.began))
            })
            .disposed(by: self.disposeBag)
        
        self.panGestureDidChange
            .bind(to: self.panTranslation)
            .disposed(by: self.disposeBag)
        
        self.appDidBecomeActive
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else { return }
                
                weakSelf.setAutoRefreshTimer()
                weakSelf.refreshWeather()
            })
            .disposed(by: self.disposeBag)
        
        self.appDidEnterBackground
            .subscribe(onNext: { [weak self] in
                self?.disposeAutoRefreshTimer()
            })
            .disposed(by: self.disposeBag)
        
        // Update favorite status on button tap
        let favoriteStatus = self.toggleFavoriteStatus
            .flatMap({
                Observable.zip(self.model.location.compactMap({ $0 }), self.isLocationFavorite)
                    .take(1)
            })
            .flatMap({ (location: WeatherLocation, isFavorite: Bool) in
                storage.saveLocationFavoriteStatus(location, isFavorite: !isFavorite)
                    .map({ Optional($0) })
                    .asDriver(onErrorJustReturn: .none)
            })
            .share()
        
        favoriteStatus
            .compactMap({ $0 })
            .bind(to: self.isLocationFavorite)
            .disposed(by: self.disposeBag)
        
        favoriteStatus
            .filter({ $0 == nil })
            .compactMap({ [weak self] _ in
                self?.getFavoriteUpdateErrorAlert()
            })
            .bind(to: self._favoriteStatusAlert)
            .disposed(by: self.disposeBag)
        
        // Map favorite state to the button title
        self.isLocationFavorite
            .asDriver(onErrorJustReturn: false)
            .map({ [weak self] (isFavorite) in
                self?.getFavoriteButton(isFavorite: isFavorite)
            })
            .drive(self._favoriteButtonTitle)
            .disposed(by: self.disposeBag)
        
        // Load the favorite state for the current location whenever it changes
        self.model.location
            .compactMap({ $0 })
            .flatMap({ location in
                storage.loadLocationFavoriteStatus(location)
                    .asDriver(onErrorJustReturn: false)
            })
            .bind(to: self.isLocationFavorite)
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.panGestureDidChange, self.didBeginPan)
            .filter({ _, didBeginPan in
                didBeginPan
            })
            .map({ translation, _ in
                translation
            })
            .map({ CGPoint(x: 0, y: $0) })
            .subscribe(onNext: { translation in
                router.route(to: .search(.changed(translation: translation)))
            })
            .disposed(by: self.disposeBag)
        
        self.panGestureDidEnd
            .withLatestFrom(Observable.combineLatest(self.panGestureDidEnd, self.panTranslation))
            .subscribe(onNext: { (velocity, translation) in
                if translation > 0 {
                    router.route(to: .search(.ended(velocity: velocity)))
                } else {
                    router.route(to: .search(.ended(velocity: CGPoint(x: 0, y: -1))))
                }
            })
            .disposed(by: self.disposeBag)
        
        self.panGestureDidEnd
            .map({ _ in false })
            .bind(to: self.didBeginPan)
            .disposed(by: self.disposeBag)
        
        self._state
            .map({ $0 == .error })
            .map({ [weak self] (isError) -> Weather.Error.ViewModel? in
                if isError {
                    return self?.getLoadError()
                }
                return nil
            })
            .bind(to: self._weatherError)
            .disposed(by: self.disposeBag)
    }
    
    func loadWeather(forLocation location: WeatherLocation) {
        let info: Weather.Location.ViewModel = self.getLocationInfo(response: location)
        self._locationInfo.accept(info)
        
        // Hide existing daily weather if loading a new location
        if self.model.matchesCurrentLocation(location) == false {
            self._dailyWeatherWillRefresh.accept(())
        }
        
        self.model.location.accept(location)
        
        // Save this location as default now (i.e. last one shown)
        self.storage.saveDefaultLocation(location)
            .sink(receiveCompletion: { _ in }, receiveValue: { })
            .store(in: &self.cancellables)
        
        // Set loading state
        self._state.accept(.loading)
        
        // Load current weather
        self.refreshWeather(forLocation: location)
    }
    
    func favoriteDidDelete(forLocation location: WeatherLocation) {
        // If this is the scene's location, update the "favorite" button
        guard self.model.matchesCurrentLocation(location) else { return }
        
        self.isLocationFavorite.accept(false)
    }
    
    //
    // MARK: - Private
    //
    
    private func refreshWeather(forLocation location: WeatherLocation) {
        let observable = self.weatherLoader.loadWeather(latitude: location.lat, longitude: location.lon)
            .asObservable()
            .share()
        
        // Identical timestamp, refresh the current weather view only
        observable
            .filter({ [model] (weather: Weather.Overview.Response) in
                model.loadTimestamp.isNearEqual(to: weather.current.lastUpdate)
            })
            .compactMap({ [weak self] (weather: Weather.Overview.Response) in
                self?.getCurrentWeather(response: weather.current, timezoneOffset: weather.timezoneOffset)
            })
            .subscribe(onNext: { [weak self] (weather: Weather.Current.ViewModel) in
                guard let weakSelf = self else { return }
                
                weakSelf._state.accept(.loaded)
                weakSelf._currentWeather.accept(weather)
            })
            .disposed(by: self.disposeBag)
        
        // Refresh all the info if we got a new data
        observable
            .filter({ [model] (weather: Weather.Overview.Response) in
                model.loadTimestamp.isNearEqual(to: weather.current.lastUpdate) == false
            })
            .do(onNext: { [weak self] (weather: Weather.Overview.Response) in
                guard let weakSelf = self else { return }
                
                weakSelf.model.loadTimestamp = weather.current.lastUpdate
                weakSelf.storage.saveLocationWeather(weather, location: location).subscribe().disposed(by: weakSelf.disposeBag)
            })
            .compactMap({ [weak self] (weather: Weather.Overview.Response) in
                self?.getWeatherOverview(response: weather)
            })
            .subscribe(onNext: { [weak self] (weather: Weather.Overview.ViewModel) in
                guard let weakSelf = self else { return }
                
                weakSelf._state.accept(.loaded)
                weakSelf._currentWeather.accept(weather.current)
                weakSelf._dailyWeatherWillRefresh.accept(())
                weakSelf._dailyWeather.accept(weather.daily)
            }, onError: { [weak self] _ in
                self?._state.accept(.error)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func getLocationInfo(response: WeatherLocation) -> Weather.Location.ViewModel {
        let title: String = response.name
        var subtitle: String = response.country
        if let state = response.state, state.isEmpty == false {
            subtitle = "\(state), \(subtitle)"
        }
        return Weather.Location.ViewModel(title: title, subtitle: subtitle, flag: UIImage(named: response.country))
    }
    
    private func getWeatherOverview(response: Weather.Overview.Response) -> Weather.Overview.ViewModel {
        let timezoneOffset: TimeInterval = response.timezoneOffset
        let current: Weather.Current.ViewModel = self.getCurrentWeather(response: response.current, timezoneOffset: timezoneOffset)
        let daily: [Weather.Day.ViewModel] = response.daily.map({ self.getDailyWeather(response: $0, timezoneOffset: timezoneOffset) })
        return Weather.Overview.ViewModel(current: current, daily: daily)
    }
    
    private func getCurrentWeather(response: Weather.Current.Response, timezoneOffset: TimeInterval) -> Weather.Current.ViewModel {
        let lastUpdate: String = self.getLastUpdate(timestamp: response.lastUpdate)
        let temperature: String = self.getTemperatureText(response.temperature)
        let description: String = response.weather.description.capitalizeFirstLetter()
        let icon: DuotoneIcon.ViewModel = self.getConditionIcon(weather: response.weather, colors: self.theme.colors.weather)
        
        // Show sunrise, sunset, snow OR rain, wind speed
        var attributesRaw: [Weather.Attribute] = [.sunrise(response.sunrise + timezoneOffset), .sunset(response.sunset + timezoneOffset)]
        
        // If we have snow info, show snow, otherwise show rain
        if response.snow > 0 {
            attributesRaw.append(.snow(response.snow))
        } else {
            attributesRaw.append(.rain(response.rain))
        }
        
        attributesRaw.append(.wind(response.windSpeed))
        
        let attributes: [Weather.Attribute.ViewModel] = attributesRaw.map(self.getAttribute)
        let lastUpdateIcon: DuotoneIcon.ViewModel = DuotoneIcon.ViewModel(icon: .clock, color: self.theme.colors.label)
        
        return Weather.Current.ViewModel(conditionIcon: icon, lastUpdate: lastUpdate, lastUpdateIcon: lastUpdateIcon, temperature: temperature, description: description, attributes: attributes)
    }
    
    private func getDailyWeather(response: Weather.Day.Response, timezoneOffset: TimeInterval) -> Weather.Day.ViewModel {
        let dayOfWeek: String = self.getDayOfWeek(timestamp: response.date + timezoneOffset)
        let date: String = self.getDate(timestamp: response.date + timezoneOffset)
        let icon: DuotoneIcon.ViewModel = self.getConditionIcon(weather: response.weather, colors: self.theme.colors.weather)
        let tempMin: Weather.Temperature.ViewModel = self.getTemperature(response.tempMin, theme: self.theme)
        let tempMax: Weather.Temperature.ViewModel = self.getTemperature(response.tempMax, theme: self.theme)
        
        // Show snow OR rain and wind speed
        var attributesRaw: [Weather.Attribute] = []
        
        // If we have snow info, show snow, otherwise show rain
        if response.snow > 0 {
            attributesRaw.append(.snow(response.snow))
        } else {
            attributesRaw.append(.rain(response.rain))
        }
        
        attributesRaw.append(.wind(response.windSpeed))
        
        let attributes: [Weather.Attribute.ViewModel] = attributesRaw.map(self.getAttribute)
        
        return Weather.Day.ViewModel(id: UUID(), dayOfWeek: dayOfWeek, date: date, conditionIcon: icon, tempMin: tempMin, tempMax: tempMax, attributes: attributes)
    }
    
    private func getDate(timestamp: TimeInterval) -> String {
        let date: Date = Date(timeIntervalSince1970: timestamp)
        
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
        
        return self.dateFormatter.string(from: date)
    }
    
    private func getTime(timestamp: TimeInterval) -> String {
        let date: Date = Date(timeIntervalSince1970: timestamp)
        
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeStyle = .short
        
        return self.dateFormatter.string(from: date)
    }
    
    private func getDayOfWeek(timestamp: TimeInterval) -> String {
        let date: Date = Date(timeIntervalSince1970: timestamp)
        
        let oldFormat: String = self.dateFormatter.dateFormat
        
        self.dateFormatter.dateFormat = "EE"
        let dayOfWeek: String = self.dateFormatter.string(from: date)
        
        self.dateFormatter.dateFormat = oldFormat
        
        return dayOfWeek
    }
    
    private func getAttribute(_ attribute: Weather.Attribute) -> Weather.Attribute.ViewModel {
        let colors: WeatherColors = self.theme.colors.weather
        
        switch attribute {
        case .rain(let amount):
            return Weather.Attribute.ViewModel(title: self.getRainAmount(amount), icon: DuotoneIcon.ViewModel(icon: .raindrops, color: colors.rain))
        case .snow(let amount):
            return Weather.Attribute.ViewModel(title: self.getSnowAmount(amount), icon: DuotoneIcon.ViewModel(icon: .snowflake, color: colors.snow))
        case .wind(let speed):
            return Weather.Attribute.ViewModel(title: self.getWindSpeed(speed), icon: DuotoneIcon.ViewModel(icon: .wind, color: colors.wind))
        case .sunrise(let time):
            return Weather.Attribute.ViewModel(title: self.getTime(timestamp: time), icon: DuotoneIcon.ViewModel(icon: .sunrise, color: colors.sun))
        case .sunset(let time):
            return Weather.Attribute.ViewModel(title: self.getTime(timestamp: time), icon: DuotoneIcon.ViewModel(icon: .sunset, color: colors.sun))
        }
    }
    
    private func getLastUpdate(timestamp: TimeInterval) -> String {
        let now: TimeInterval = Date().timeIntervalSince1970
        let diff: TimeInterval = now - timestamp
        let minutes: UInt = UInt(max(floor(diff / 60), 0))
        
        // "Just now"
        if minutes < 1 {
            return NSLocalizedString("currentWeatherLastUpdateJustNowText", comment: "")
        }
        
        // "X minutes ago"
        if minutes < 60 {
            let format: String = NSLocalizedString("num_minutes_ago", comment: "")
            return String.localizedStringWithFormat(format, minutes)
        }
        
        // "X hours ago"
        let hours: UInt = minutes / 60
        if hours < 24 {
            let format: String = NSLocalizedString("num_hours_ago", comment: "")
            return String.localizedStringWithFormat(format, hours)
        }
        
        // "X days ago"
        let days: UInt = hours / 24
        let format: String = NSLocalizedString("num_days_ago", comment: "")
        return String.localizedStringWithFormat(format, days)
    }
    
    private func getFavoriteButton(isFavorite: Bool) -> IconButton.ViewModel {
        let title: String
        let font: UIFont
        
        if isFavorite {
            title = NSLocalizedString("locationRemoveFromFavoritesButton", comment: "")
            font = self.theme.fonts.iconSolid(style: .caption1)
        } else {
            title = NSLocalizedString("locationAddToFavoritesButton", comment: "")
            font = self.theme.fonts.iconLight(style: .caption1)
        }
        
        return IconButton.ViewModel(icon: .heart, title: title, font: font)
    }
    
    private func getFavoriteUpdateErrorAlert() -> Alert.ViewModel {
        let title: String = NSLocalizedString("locationFavoriteErrorTitle", comment: "")
        let message: String = NSLocalizedString("locationFavoriteErrorMessage", comment: "")
        let button: String = NSLocalizedString("okAlertButton", comment: "")
        return Alert.ViewModel(title: title, message: message, button: button)
    }
    
    private func setAutoRefreshTimer() {
        guard self.autoRefreshDisposable == nil else { return }
        
        self.autoRefreshDisposable = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshWeather()
            })
    }
    
    private func disposeAutoRefreshTimer() {
        guard let disposable = self.autoRefreshDisposable else { return }
        
        self.autoRefreshDisposable = nil
        disposable.dispose()
    }
    
    private func refreshWeather() {
        guard let location = self.model.location.value else { return }
        
        self.refreshWeather(forLocation: location)
    }
    
    private func getLoadError() -> Weather.Error.ViewModel {
        let icon: DuotoneIcon.ViewModel = DuotoneIcon.ViewModel(icon: .thunderstorm, primaryColor: self.theme.colors.weather.cloud, secondaryColor: self.theme.colors.weather.sun)
        return Weather.Error.ViewModel(icon: icon, message: NSLocalizedString("weatherLoadErrorMessage", comment: ""))
    }

}
