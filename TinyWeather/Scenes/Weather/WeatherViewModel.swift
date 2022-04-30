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
import UIKit
import TWThemes
import TWExtensions
import TWModels
import TWRoutes
import Combine

protocol WeatherViewModelInputs {
    var panGestureDidBegin: PassthroughSubject<Void, Never> { get }
    var panGestureDidChange: PassthroughSubject<CGFloat, Never> { get }
    var panGestureDidEnd: PassthroughSubject<CGPoint, Never> { get }
    var toggleFavoriteStatus: PassthroughSubject<Void, Never> { get }
    var appDidEnterBackground: PassthroughSubject<Void, Never> { get }
    var appDidBecomeActive: PassthroughSubject<Void, Never> { get }
}

protocol WeatherViewModelOutputs {
    var locationInfo: AnyPublisher<Weather.Location.ViewModel, Never> { get }
    var state: AnyPublisher<Weather.State, Never> { get }
    var currentWeather: AnyPublisher<Weather.Current.ViewModel, Never> { get }
    var dailyWeatherWillRefresh: AnyPublisher<Void, Never> { get }
    var newDailyWeather: AnyPublisher<Weather.Day.ViewModel, Never> { get }
    var favoriteButtonTitle: AnyPublisher<IconButton.ViewModel?, Never> { get }
    var favoriteStatusAlert: AnyPublisher<Alert.ViewModel, Never> { get }
    var weatherError: AnyPublisher<Weather.Error.ViewModel?, Never> { get }
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
    private let dateFormatter: DateFormatter = DateFormatter()
    
    private let weatherLoader: WeatherLoading
    private let router: WeakRouter<AppRoute>
    private let storage: WeatherStorageManaging
    
    private var model: Weather.Model = Weather.Model()
    
    private var didBeginPan: CurrentValueSubject<Bool, Never> = CurrentValueSubject(false)
    private var panTranslation: CurrentValueSubject<CGFloat, Never> = CurrentValueSubject(0)
    
    private var autoRefreshCancellable: Cancellable?

    var inputs: WeatherViewModelInputs { return self }
    var outputs: WeatherViewModelOutputs { return self }
    
    let theme: Theme

    // Inputs
    let panGestureDidBegin: PassthroughSubject<Void, Never> = PassthroughSubject()
    let panGestureDidChange: PassthroughSubject<CGFloat, Never> = PassthroughSubject()
    let panGestureDidEnd: PassthroughSubject<CGPoint, Never> = PassthroughSubject()
    let toggleFavoriteStatus: PassthroughSubject<Void, Never> = PassthroughSubject()
    let appDidEnterBackground: PassthroughSubject<Void, Never> = PassthroughSubject()
    let appDidBecomeActive: PassthroughSubject<Void, Never> = PassthroughSubject()

    // Outputs
    private let _locationInfo: CurrentValueSubject<Weather.Location.ViewModel?, Never> = CurrentValueSubject(nil)
    let locationInfo: AnyPublisher<Weather.Location.ViewModel, Never>
    
    private let _state: CurrentValueSubject<Weather.State, Never> = CurrentValueSubject(.loading)
    let state: AnyPublisher<Weather.State, Never>
    
    private let _currentWeather: CurrentValueSubject<Weather.Current.ViewModel?, Never> = CurrentValueSubject(nil)
    let currentWeather: AnyPublisher<Weather.Current.ViewModel, Never>
    
    private let _dailyWeatherWillRefresh: PassthroughSubject<Void, Never> = PassthroughSubject()
    let dailyWeatherWillRefresh: AnyPublisher<Void, Never>
    
    private let _dailyWeather: CurrentValueSubject<[Weather.Day.ViewModel?]?, Never> = CurrentValueSubject(nil)
    let newDailyWeather: AnyPublisher<Weather.Day.ViewModel, Never>
    
    private let isLocationFavorite: CurrentValueSubject<Bool, Never> = CurrentValueSubject(false)
    private let _favoriteButtonTitle: CurrentValueSubject<IconButton.ViewModel?, Never> = CurrentValueSubject(nil)
    let favoriteButtonTitle: AnyPublisher<IconButton.ViewModel?, Never>
    
    private let _favoriteStatusAlert: PassthroughSubject<Alert.ViewModel, Never> = PassthroughSubject()
    let favoriteStatusAlert: AnyPublisher<Alert.ViewModel, Never>
    
    private let _weatherError: PassthroughSubject<Weather.Error.ViewModel?, Never> = PassthroughSubject()
    let weatherError: AnyPublisher<Weather.Error.ViewModel?, Never>

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
        
        self.locationInfo = _locationInfo.asDriver().compactMap({ $0 }).eraseToAnyPublisher()
        self.currentWeather = _currentWeather.asDriver().compactMap({ $0 }).eraseToAnyPublisher()
        
        self.dailyWeatherWillRefresh = _dailyWeatherWillRefresh.asDriver(onErrorJustReturn: ())
        self.newDailyWeather = _dailyWeather
            .compactMap({ $0 })
            .flatMap({
                $0.publisher
            })
            .asDriver(onErrorJustReturn: nil)
            .compactMap({ $0 })
            .eraseToAnyPublisher()
        
        self.favoriteButtonTitle = _favoriteButtonTitle.asDriver(onErrorJustReturn: nil)
        self.favoriteStatusAlert = _favoriteStatusAlert.eraseToAnyPublisher()
        
        self.weatherError = _weatherError.asDriver(onErrorJustReturn: nil)
        
        // Init auto-refresh timer
        self.setAutoRefreshTimer()
        
        self.panGestureDidBegin
            .map({ true })
            .assign(to: \.value, on: self.didBeginPan)
            .store(in: &self.cancellables)
        
        self.panGestureDidBegin
            .sink(receiveValue: {
                router.route(to: .search(.began))
            })
            .store(in: &self.cancellables)
        
        self.panGestureDidChange
            .assign(to: \.value, on: self.panTranslation)
            .store(in: &self.cancellables)
        
        self.appDidBecomeActive
            .sink(receiveValue: { [weak self] in
                guard let weakSelf = self else { return }
                
                weakSelf.setAutoRefreshTimer()
                weakSelf.refreshWeather()
            })
            .store(in: &self.cancellables)
        
        self.appDidEnterBackground
            .sink(receiveValue: {[weak self] in
                self?.disposeAutoRefreshTimer()
            })
            .store(in: &self.cancellables)
        
        // Update favorite status on button tap
        let favoriteStatus = self.toggleFavoriteStatus
            .flatMap({
                Publishers.Zip(self.model.location.compactMap({ $0 }).eraseToAnyPublisher(), self.isLocationFavorite.eraseToAnyPublisher())
                    .prefix(1)
                    .eraseToAnyPublisher()
            })
            .flatMap({ (location: WeatherLocation, isFavorite: Bool) in
                storage.saveLocationFavoriteStatus(location, isFavorite: !isFavorite)
                    .map({ Optional($0) })
                    .asDriver(onErrorJustReturn: .none)
            })
            .share()
        
        favoriteStatus
            .compactMap({ $0 })
            .assign(to: \.value, on: self.isLocationFavorite)
            .store(in: &self.cancellables)

        favoriteStatus
            .filter({ $0 == nil })
            .compactMap({ [weak self] _ in
                self?.getFavoriteUpdateErrorAlert()
            })
            .sink(receiveValue: { [weak self] vm in
                self?._favoriteStatusAlert.send(vm)
            })
            .store(in: &self.cancellables)
        
        // Map favorite state to the button title
        self.isLocationFavorite
            .asDriver(onErrorJustReturn: false)
            .map({ [weak self] (isFavorite) in
                self?.getFavoriteButton(isFavorite: isFavorite)
            })
            .assign(to: \.value, on: _favoriteButtonTitle)
            .store(in: &self.cancellables)
        
        // Load the favorite state for the current location whenever it changes
        self.model.location
            .compactMap({ $0 })
            .flatMap({ location in
                storage.loadLocationFavoriteStatus(location)
                    .asDriver(onErrorJustReturn: false)
            })
            .assign(to: \.value, on: self.isLocationFavorite)
            .store(in: &self.cancellables)
        
        Publishers.CombineLatest(self.panGestureDidChange, self.didBeginPan)
            .filter({ _, didBeginPan in
                didBeginPan
            })
            .map({ translation, _ in
                translation
            })
            .map({ CGPoint(x: 0, y: $0) })
            .sink(receiveValue: { translation in
                router.route(to: .search(.changed(translation: translation)))
            })
            .store(in: &self.cancellables)
        
        self.panGestureDidEnd
            .flatMap({ [panTranslation] velocity in
                Publishers.CombineLatest(Just(velocity).eraseToAnyPublisher(), panTranslation.eraseToAnyPublisher())
                    .first()
            })
            .sink(receiveValue: { (velocity, translation) in
                if translation > 0 {
                    router.route(to: .search(.ended(velocity: velocity)))
                } else {
                    router.route(to: .search(.ended(velocity: CGPoint(x: 0, y: -1))))
                }
            })
            .store(in: &self.cancellables)
        
        self.panGestureDidEnd
            .map({ _ in false })
            .assign(to: \.value, on: self.didBeginPan)
            .store(in: &self.cancellables)
        
        self._state
            .map({ $0 == .error })
            .map({ [weak self] (isError) -> Weather.Error.ViewModel? in
                if isError {
                    return self?.getLoadError()
                }
                return nil
            })
            .sink(receiveValue: { [weak self] vm in
                self?._weatherError.send(vm)
            })
            .store(in: &self.cancellables)
    }
    
    func loadWeather(forLocation location: WeatherLocation) {
        let info: Weather.Location.ViewModel = self.getLocationInfo(response: location)
        self._locationInfo.send(info)
        
        // Hide existing daily weather if loading a new location
        if self.model.matchesCurrentLocation(location) == false {
            self._dailyWeatherWillRefresh.send(())
        }
        
        self.model.location.send(location)
        
        // Save this location as default now (i.e. last one shown)
        self.storage.saveDefaultLocation(location)
            .sink(receiveCompletion: { _ in }, receiveValue: { })
            .store(in: &self.cancellables)
        
        // Set loading state
        self._state.send(.loading)
        
        // Load current weather
        self.refreshWeather(forLocation: location)
    }
    
    func favoriteDidDelete(forLocation location: WeatherLocation) {
        // If this is the scene's location, update the "favorite" button
        guard self.model.matchesCurrentLocation(location) else { return }
        
        self.isLocationFavorite.send(false)
    }
    
    //
    // MARK: - Private
    //
    
    private func refreshWeather(forLocation location: WeatherLocation) {
        let observable = self.weatherLoader.loadWeather(latitude: location.lat, longitude: location.lon)
            .share()
        
        // Identical timestamp, refresh the current weather view only
        observable
            .filter({ [model] (weather: Weather.Overview.Response) in
                model.loadTimestamp.isNearEqual(to: weather.current.lastUpdate)
            })
            .compactMap({ [weak self] (weather: Weather.Overview.Response) in
                self?.getCurrentWeather(response: weather.current, timezoneOffset: weather.timezoneOffset)
            })
            .sink(receiveCompletion: { completion in
                // Error handled in the other subscriber below
            }, receiveValue: { [weak self] (weather: Weather.Current.ViewModel) in
                guard let weakSelf = self else { return }
                
                weakSelf._state.send(.loaded)
                weakSelf._currentWeather.send(weather)
            })
            .store(in: &self.cancellables)
        
        // Refresh all the info if we got a new data
        observable
            .filter({ [model] (weather: Weather.Overview.Response) in
                model.loadTimestamp.isNearEqual(to: weather.current.lastUpdate) == false
            })
            .handleEvents(receiveOutput: { [weak self] (weather: Weather.Overview.Response) in
                guard let weakSelf = self else { return }
                
                weakSelf.model.loadTimestamp = weather.current.lastUpdate
                weakSelf.storage.saveLocationWeather(weather, location: location).sink(receiveCompletion: { _ in }, receiveValue: { }).store(in: &weakSelf.cancellables)
            })
            .compactMap({ [weak self] (weather: Weather.Overview.Response) in
                self?.getWeatherOverview(response: weather)
            })
            .sink(receiveCompletion: { [weak self] (completion) in
                if case .failure = completion {
                    self?._state.send(.error)
                }
            }, receiveValue: { [weak self] (weather: Weather.Overview.ViewModel) in
                guard let weakSelf = self else { return }
                
                weakSelf._state.send(.loaded)
                weakSelf._currentWeather.send(weather.current)
                weakSelf._dailyWeatherWillRefresh.send(())
                weakSelf._dailyWeather.send(weather.daily)
            })
            .store(in: &self.cancellables)
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
        guard self.autoRefreshCancellable == nil else { return }
        
        self.autoRefreshCancellable = Timer.publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in
                self?.refreshWeather()
            })
    }
    
    private func disposeAutoRefreshTimer() {
        guard let disposable = self.autoRefreshCancellable else { return }
        
        self.autoRefreshCancellable = nil
        disposable.cancel()
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
