//
//  WeatherViewModel+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
import TWThemes
import TWRoutes
import TWModels
import Combine
@testable import TinyWeather

class WeatherViewModel_Tests: XCTestCase, WeatherConditionPresenting, WindSpeedPresenting, RainAmountPresenting, SnowAmountPresenting {
    
    private var sut: WeatherViewModelProtocol!
    
    private var weatherLoader: WeatherLoadingMock!
    private var routerMock: RouterMock!
    private var router: WeakRouter<AppRoute>!
    private var storage: WeatherStorageMock!
    private var dateFormatter: DateFormatter!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.weatherLoader = WeatherLoadingMock()
        self.weatherLoader.weather = TestWeather.current
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.sut = WeatherViewModel(theme: AppTheme(), weatherLoader: weatherLoader, router: router, storage: storage)
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.timeStyle = .short
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")!
        self.dateFormatter.locale = Locale.current
        self.cancellables = []
    }

    override func tearDownWithError() throws {
        self.cancellables = nil
    }

    func test_actions_called_after_calling_load_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        let outputs = self.sut.outputs
        
        let state = try awaitPublisher(outputs.state.first()).get()
        
        XCTAssertEqual(state, .loading)
        XCTAssertEqual(self.weatherLoader.numLoadWeatherCalls, 0)
        XCTAssertEqual(self.weatherLoader.numLoadWeatherSubscriptions, 0)
        XCTAssertEqual(self.storage.numSaveDefaultLocationCalls, 0)
        
        self.sut.loadWeather(forLocation: location)
        
        XCTAssertEqual(self.weatherLoader.numLoadWeatherCalls, 1)
        XCTAssertEqual(self.weatherLoader.numLoadWeatherSubscriptions, 1)
        XCTAssertEqual(self.storage.numSaveDefaultLocationCalls, 1)
        
        let locationVM = try awaitPublisher(outputs.locationInfo.first()).get()
        XCTAssertEqual(locationVM.title, location.name)
        XCTAssertEqual(locationVM.subtitle, "\(location.state!), \(location.country)")
    }
    
    func test_state_after_successfully_loading_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        let outputs = self.sut.outputs
        
        let stateInit = try awaitPublisher(outputs.state.first()).get()
        
        XCTAssertEqual(stateInit, .loading)
        
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        
        outputs.state
            .sink(receiveValue: { state in
                if state == .loaded {
                    expect.fulfill()
                }
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_state_after_failing_to_load_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        let outputs = self.sut.outputs
        
        let stateInit = try awaitPublisher(outputs.state.first()).get()
        
        XCTAssertEqual(stateInit, .loading)
        
        self.weatherLoader.shouldFail = true
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        
        outputs.state
            .sink(receiveValue: { state in
                if state == .error {
                    expect.fulfill()
                }
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_current_weather_driver_after_loading_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        let outputs = self.sut.outputs
        
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        
        outputs.currentWeather
            .sink(receiveValue: { currentWeather in
                XCTAssertEqual(currentWeather.attributes.count, 4)
                XCTAssertEqual(currentWeather.description, "Rainy")
                XCTAssertEqual(currentWeather.temperature, "10°C")
                
                let sunrise = currentWeather.attributes.first(where: { $0.icon.icon == .sunrise })!
                let sunset = currentWeather.attributes.first(where: { $0.icon.icon == .sunset })!
                let wind = currentWeather.attributes.first(where: { $0.icon.icon == .wind })!
                
                let weatherResponse = self.weatherLoader.weather
                
                XCTAssertEqual(sunrise.title, self.getTime(timestamp: weatherResponse!.current.sunrise))
                XCTAssertEqual(sunset.title, self.getTime(timestamp: weatherResponse!.current.sunset))
                XCTAssertEqual(wind.title, self.getWindSpeed(weatherResponse!.current.windSpeed))
                
                if let rain = currentWeather.attributes.first(where: { $0.icon.icon == .raindrops }) {
                    XCTAssertEqual(rain.title, self.getRainAmount(weatherResponse!.current.rain))
                } else if let snow = currentWeather.attributes.first(where: { $0.icon.icon == .snowflake }) {
                    XCTAssertEqual(snow.title, self.getSnowAmount(weatherResponse!.current.snow))
                } else {
                    XCTFail("missing rain/snow attribute")
                }
                
                expect.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_daily_weather_driver_after_loading_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        let outputs = self.sut.outputs
        let numDaily: Int = self.weatherLoader.weather.daily.count
        var numDailyWeathersReceived: Int = 0
        
        self.sut.loadWeather(forLocation: location)
        
        var didReceiveDailyWeather: Bool = false
        
        let expectDailyWeatherWillRefresh = expectation(description: #function)
        let expectNewDailyWeather = expectation(description: #function)
        
        outputs.dailyWeatherWillRefresh
            .sink(receiveValue: {
                XCTAssertFalse(didReceiveDailyWeather)
                
                expectDailyWeatherWillRefresh.fulfill()
            })
            .store(in: &self.cancellables)
        
        outputs.newDailyWeather
            .sink(receiveValue: { weather in
                didReceiveDailyWeather = true
                
                let response = self.weatherLoader.weather.daily[numDailyWeathersReceived]
                let icon: FontIcon = self.getConditionIcon(weather: response.weather, colors: AppTheme().colors.weather).icon
                
                XCTAssertEqual(weather.conditionIcon.icon, icon)
                XCTAssertEqual(weather.date, self.getDate(timestamp: response.date))
                XCTAssertEqual(weather.dayOfWeek, self.getDayOfWeek(timestamp: response.date))
                XCTAssertEqual(weather.attributes.count, 2)
                
                let wind = weather.attributes.first(where: { $0.icon.icon == .wind })!
                XCTAssertEqual(wind.title, self.getWindSpeed(response.windSpeed))
                
                if let rain = weather.attributes.first(where: { $0.icon.icon == .raindrops }) {
                    XCTAssertEqual(rain.title, self.getRainAmount(response.rain))
                } else if let snow = weather.attributes.first(where: { $0.icon.icon == .snowflake }) {
                    XCTAssertEqual(snow.title, self.getSnowAmount(response.snow))
                } else {
                    XCTFail("missing rain/snow attribute")
                }
                
                numDailyWeathersReceived += 1
                
                if numDailyWeathersReceived == numDaily {
                    expectNewDailyWeather.fulfill()
                }
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_status_is_loaded_after_calling_load_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        
        XCTAssertEqual(self.storage.numLoadLocationFavoriteStatusCalls, 0)
        
        self.sut.loadWeather(forLocation: location)
        
        XCTAssertEqual(self.storage.numLoadLocationFavoriteStatusCalls, 1)
    }
    
    func test_favorite_button_title_for_unfavorite_location_after_calling_load_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        
        self.storage.loadLocationFavoriteStatusValue = false
        
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        
        let outputs = self.sut.outputs
        outputs.favoriteButtonTitle
            .compactMap({ $0 })
            .sink(receiveValue: { vm in
                XCTAssertEqual(vm.icon, .heart)
                XCTAssertEqual(vm.title, NSLocalizedString("locationAddToFavoritesButton", comment: ""))
                
                expect.fulfill()
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_button_title_for_favorite_location_after_calling_load_weather() throws {
        let location: WeatherLocation = TestLocations.location1
        
        self.storage.loadLocationFavoriteStatusValue = true
        
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        var expectedTitles: [String] = [
            NSLocalizedString("locationAddToFavoritesButton", comment: ""), // Title for initial value
            NSLocalizedString("locationRemoveFromFavoritesButton", comment: "")
        ]
        
        let outputs = self.sut.outputs
        outputs.favoriteButtonTitle
            .compactMap({ $0 })
            .sink(receiveValue: { vm in
                XCTAssertEqual(vm.icon, .heart)
                
                let title = expectedTitles.removeFirst()
                XCTAssertEqual(vm.title, title)
                
                if expectedTitles.isEmpty {
                    expect.fulfill()
                }
            })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_save_location_favorite_status_is_called_after_favorite_button_tap() throws {
        let location: WeatherLocation = TestLocations.location1
        
        self.storage.loadLocationFavoriteStatusValue = false
        
        XCTAssertEqual(self.storage.numSaveLocationFavoriteStatusCalls, 0)
        
        self.sut.loadWeather(forLocation: location)
        
        let inputs = self.sut.inputs
        inputs.toggleFavoriteStatus.send(())
        
        XCTAssertEqual(self.storage.numSaveLocationFavoriteStatusCalls, 1)
        XCTAssertEqual(self.storage.saveLocationFavoriteStatusArgumentValue, true)
        
        // Have to wait to propagate the new favorite status to other publishers in the view model (?)
        let _ = try awaitPublisher(Timer.publish(every: 0.1, on: .main, in: .default).autoconnect().first())
        
        inputs.toggleFavoriteStatus.send(())
        
        XCTAssertEqual(self.storage.numSaveLocationFavoriteStatusCalls, 2)
        XCTAssertEqual(self.storage.saveLocationFavoriteStatusArgumentValue, false)
    }
    
    func test_favorite_button_title_after_favorite_button_tap() throws {
        let location: WeatherLocation = TestLocations.location1
        
        self.storage.loadLocationFavoriteStatusValue = false
        
        self.sut.loadWeather(forLocation: location)
        
        let outputs = self.sut.outputs
        outputs.favoriteButtonTitle
            .compactMap({ $0 })
            .prefix(3)
            .collect()
            .sink(receiveValue: { vms in
                XCTAssertEqual(vms.count, 3)
                
                // Default title
                XCTAssertEqual(vms[0].title, NSLocalizedString("locationAddToFavoritesButton", comment: ""))
                
                // Tapped, added to favorites
                XCTAssertEqual(vms[1].title, NSLocalizedString("locationRemoveFromFavoritesButton", comment: ""))
                
                // Tapped, removed from favorites
                XCTAssertEqual(vms[2].title, NSLocalizedString("locationAddToFavoritesButton", comment: ""))
            })
            .store(in: &self.cancellables)
        
        let inputs = self.sut.inputs
        inputs.toggleFavoriteStatus.send(())
        inputs.toggleFavoriteStatus.send(())
    }
    
    func test_favorite_error_alert_is_published_after_favorite_status_fails_to_update() throws {
        let location: WeatherLocation = TestLocations.location1
        
        self.sut.loadWeather(forLocation: location)
        
        let expect = expectation(description: #function)
        
        let outputs = self.sut.outputs
        outputs.favoriteStatusAlert
            .sink(receiveValue: { alert in
                XCTAssertEqual(alert.button, NSLocalizedString("okAlertButton", comment: ""))
                XCTAssertEqual(alert.message, NSLocalizedString("locationFavoriteErrorMessage", comment: ""))
                XCTAssertEqual(alert.title, NSLocalizedString("locationFavoriteErrorTitle", comment: ""))
                
                expect.fulfill()
            })
            .store(in: &self.cancellables)
        
        self.storage.shouldFail = true
        
        let inputs = self.sut.inputs
        inputs.toggleFavoriteStatus.send(())
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    //
    // MARK: - Private
    //
    
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

}
