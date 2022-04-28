//
//  SearchViewModel+Tests.swift
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
import RxSwift
@testable import TinyWeather

class SearchViewModel_Tests: XCTestCase, CoordinatesPresenting {

    private var sut: SearchViewModelProtocol!
    
    private var routerMock: RouterMock!
    private var router: WeakRouter<AppRoute>!
    private var storage: WeatherStorageMock!
    private var apiService: RequestExecutingGeo!
    private var disposeBag: DisposeBag! = DisposeBag()
    
    override func setUpWithError() throws {
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.apiService = RequestExecutingGeo()
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
    }
    
    override func tearDownWithError() throws {
        self.disposeBag = nil
    }
    
    func test_search_field_placeholder() {
        let outputs = self.sut.outputs
        
        let expect = expectation(description: #function)
        
        outputs.searchPlaceholder
            .compactMap({ $0 })
            .drive(onNext: { val in
                XCTAssertEqual(val.string, NSLocalizedString("searchInputPlaceholder", comment: ""))
                
                expect.fulfill()
            })
            .disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_location_button_title() {
        let outputs = self.sut.outputs
        
        let expect = expectation(description: #function)
        
        outputs.locationButtonTitle
            .drive(onNext: { val in
                XCTAssertEqual(val.title, NSLocalizedString("searchDeviceLocationButton", comment: ""))
                XCTAssertEqual(val.icon, .location)
                
                expect.fulfill()
            })
            .disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_search_hints_for_search_value() throws {
        let inputs = self.sut.inputs
        let outputs = self.sut.outputs
        
        let expect1 = expectation(description: "initial loading")
        let expect2 = expectation(description: "loaded hints")
        let expect3 = expectation(description: "loading again")
        let expect4 = expectation(description: "no results for query")
        let expect5 = expectation(description: "no hints for empty query")
        
        outputs.searchHints
            .asObservable()
            .take(5)
            .toArray()
            .subscribe(onSuccess: { values in
                XCTAssertEqual(values.count, 5)
                
                // Loading
                let hint1 = try! XCTUnwrap(values[0])
                switch hint1 {
                case .loading:
                    expect1.fulfill()
                default:
                    XCTFail("invalid hint, should be 'loading'")
                }
                
                // Results
                let hint2 = try! XCTUnwrap(values[1])
                switch hint2 {
                case .results(let cities):
                    XCTAssertEqual(cities.count, ResponseGeo.successResponse.count)
                    
                    for (vm, json) in zip(cities, ResponseGeo.successResponse) {
                        var title = json.string("name")
                        if let state = json.stringOptional("state") {
                            title = "\(title), \(state)"
                        }
                        
                        let lat = json.double("lat")
                        let lon = json.double("lon")
                        
                        XCTAssertEqual(vm.title, title)
                        XCTAssertEqual(vm.subtitle, self.getCoords(lat: lat, lon: lon))
                    }
                    
                    expect2.fulfill()
                case .error, .loading, .empty:
                    XCTFail("invalid hint, should be 'results'")
                }
                
                // Loading again
                let hint3 = try! XCTUnwrap(values[2])
                switch hint3 {
                case .loading:
                    expect3.fulfill()
                default:
                    XCTFail("invalid hint, should be 'loading'")
                }
                
                // No results
                let hint4 = try! XCTUnwrap(values[3])
                switch hint4 {
                case .empty(let message):
                    XCTAssertEqual(message, NSLocalizedString("searchHintsNoResultsMessage", comment: ""))
                    
                    expect4.fulfill()
                case .error, .loading, .results:
                    XCTFail("invalid hint, should be 'empty'")
                }
                
                // No hints
                let hint5 = values[4]
                XCTAssertNil(hint5)
                
                expect5.fulfill()
                
                // Verify number of api service calls
                XCTAssertEqual(self.apiService.numExecuteCalls, 2)
            })
            .disposed(by: self.disposeBag)
        
        self.apiService.shouldRespondWithEmpty = false
        
        inputs.searchValue.accept("London")
        inputs.performSearch.onNext(())
        
        self.apiService.shouldRespondWithEmpty = true
        
        inputs.searchValue.accept("no results")
        inputs.performSearch.onNext(())
        
        inputs.searchValue.accept("")
        inputs.performSearch.onNext(())
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_search_hint_error_message() {
        let inputs = self.sut.inputs
        let outputs = self.sut.outputs
        
        let expect1 = expectation(description: "initial loading")
        let expect2 = expectation(description: "error hint message")
        
        self.apiService.shouldFail = true
        
        outputs.searchHints
            .asObservable()
            .take(2)
            .toArray()
            .subscribe(onSuccess: { values in
                XCTAssertEqual(values.count, 2)
                
                // Loading
                let hint1 = try! XCTUnwrap(values[0])
                switch hint1 {
                case .loading:
                    expect1.fulfill()
                default:
                    XCTFail("invalid hint, should be 'loading'")
                }
                
                // Error
                let hint2 = try! XCTUnwrap(values[1])
                switch hint2 {
                case .error(let message):
                    XCTAssertEqual(message, NSLocalizedString("searchHintsErrorMessage", comment: ""))
                    expect2.fulfill()
                case .results, .loading, .empty:
                    XCTFail("invalid hint, should be 'results'")
                }
                
                // Verify number of api service calls
                XCTAssertEqual(self.apiService.numExecuteCalls, 1)
            })
            .disposed(by: self.disposeBag)
        
        inputs.searchValue.accept("London")
        inputs.performSearch.onNext(())
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_locations_are_loaded_on_init() {
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.apiService = RequestExecutingGeo()
        
        XCTAssertEqual(self.storage.numLoadFavoriteLocationsCalls, 0)
        
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
        
        XCTAssertEqual(self.storage.numLoadFavoriteLocationsCalls, 1)
    }
    
    func test_no_favorite_locations_message() {
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.apiService = RequestExecutingGeo()
        
        let expect = expectation(description: #function)
        
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
        
        let outputs = self.sut.outputs
        outputs.favorites
            .drive(onNext: { vm in
                if case .none(let message) = vm {
                    XCTAssertEqual(message, NSLocalizedString("noFavoritesMessage", comment: ""))
                    
                    expect.fulfill()
                }
            })
            .disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_locations_output() {
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.storage.favoriteLocations = [TestLocations.location1, TestLocations.location2]
        self.apiService = RequestExecutingGeo()
        
        let expect = expectation(description: #function)
        
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
        
        let outputs = self.sut.outputs
        outputs.favorites
            .drive(onNext: { vm in
                if case .saved(let title, let locations) = vm {
                    let expectedTitle = String.localizedStringWithFormat(NSLocalizedString("numberOfFavoritesTitle", comment: ""), self.storage.favoriteLocations.count)
                    XCTAssertEqual(title, expectedTitle)
                    
                    XCTAssertEqual(locations.count, self.storage.favoriteLocations.count)
                    
                    for (vm, model) in zip(locations, self.storage.favoriteLocations) {
                        var title = model.name
                        if let state = model.state {
                            title = "\(title), \(state)"
                        }
                        
                        XCTAssertEqual(vm.title, title)
                        XCTAssertEqual(vm.subtitle, self.getCoords(lat: model.lat, lon: model.lon))
                    }
                    
                    expect.fulfill()
                }
            })
            .disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_tap_will_hide_scene() {
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.storage.favoriteLocations = [TestLocations.location1, TestLocations.location2]
        self.apiService = RequestExecutingGeo()
        
        let expect = expectation(description: #function)
        
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
        
        let outputs = self.sut.outputs
        outputs.sceneWillHide
            .subscribe(onNext: {
                expect.fulfill()
            })
            .disposed(by: self.disposeBag)
        
        let inputs = self.sut.inputs
        inputs.favoriteLocationDidSelect.accept(1)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_favorite_tap_will_route_to_weather() throws {
        let tapLocation: WeatherLocation = TestLocations.location2
        
        self.routerMock = RouterMock()
        let router = WeakRouter<AppRoute>(self.routerMock)
        self.storage = WeatherStorageMock()
        self.storage.favoriteLocations = [TestLocations.location1, tapLocation]
        self.apiService = RequestExecutingGeo()
        
        self.sut = SearchViewModel(apiService: apiService, theme: AppTheme(), router: router, storage: storage, isInteractiveAnimationEnabled: false)
        
        let inputs = self.sut.inputs
        inputs.favoriteLocationDidSelect.accept(1)
        
        let route: AppRoute = try XCTUnwrap(self.routerMock.calledRoute)
        
        switch route {
        case .weather(let location):
            XCTAssertEqual(location.name, tapLocation.name)
            XCTAssertEqual(location.state, tapLocation.state)
            XCTAssertEqual(location.country, tapLocation.country)
            XCTAssertEqual(location.lat, tapLocation.lat, accuracy: 0.0001)
            XCTAssertEqual(location.lon, tapLocation.lon, accuracy: 0.0001)
            
        default:
            XCTFail("incorrect route")
        }
    }
    
    func test_search_hint_tap_will_hide_scene() {
        let inputs = self.sut.inputs
        let outputs = self.sut.outputs
        
        let expect = expectation(description: #function)
        
        self.apiService.shouldRespondWithEmpty = false
        
        inputs.searchValue.accept("London")
        inputs.performSearch.onNext(())
        
        outputs.sceneWillHide
            .subscribe(onNext: {
                expect.fulfill()
            })
            .disposed(by: self.disposeBag)
        
        inputs.locationHintTap.accept(1)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
    
    func test_search_hint_tap_will_route_to_weather() throws {
        let inputs = self.sut.inputs
        
        self.apiService.shouldRespondWithEmpty = false
        
        inputs.searchValue.accept("London")
        inputs.performSearch.onNext(())
        
        inputs.locationHintTap.accept(1)
        
        let route: AppRoute = try XCTUnwrap(self.routerMock.calledRoute)
        
        switch route {
        case .weather(let location):
            XCTAssertEqual(location.name, "City of London")
            XCTAssertEqual(location.country, "GB")
            XCTAssertNil(location.state)
            XCTAssertEqual(location.lat, 51.5156177, accuracy: 0.0001)
            XCTAssertEqual(location.lon, -0.0919983, accuracy: 0.0001)
            
        default:
            XCTFail("incorrect route")
        }
    }

}
