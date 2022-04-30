//
//  SearchViewModel.swift
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
import TWRoutes
import TWModels
import CoreLocation
import Combine

protocol SearchViewModelInputs {
    var animationDidStart: PassthroughSubject<Void, Never> { get }
    var animationDidComplete: PassthroughSubject<Bool, Never> { get }
    var viewDidDisappear: PassthroughSubject<Void, Never> { get }
    var searchFieldDidBeginEditing: PassthroughSubject<Void, Never> { get }
    
    var searchValue: CurrentValueSubject<String?, Never> { get }
    var performSearch: PassthroughSubject<Void, Never> { get }
    var locationHintTap: PassthroughSubject<Int, Never> { get }
    var searchByLocation: PassthroughSubject<Void, Never> { get }
    var favoriteLocationDidSelect: PassthroughSubject<Int, Never> { get }
    var favoriteLocationDidDelete: PassthroughSubject<Int, Never> { get }
}

protocol SearchViewModelOutputs {
    var searchPlaceholder: AnyPublisher<NSAttributedString?, Never> { get }
    var locationButtonTitle: AnyPublisher<DuotoneIconButton.ViewModel, Never> { get }
    var animationState: Search.AnimationState { get }
    var searchHints: AnyPublisher<Search.SearchHints?, Never> { get }
    var sceneDidHide: AnyPublisher<Void, Never> { get }
    var sceneWillHide: AnyPublisher<Void, Never> { get }
    var sceneDidAppear: AnyPublisher<Void, Never> { get }
    var isInteractiveAnimationEnabled: Bool { get }
    var favorites: AnyPublisher<Search.Favorites.ViewModel, Never> { get }
    var favoriteDeleteAlert: AnyPublisher<Alert.ViewModel, Never> { get }
    var favoriteDidDelete: AnyPublisher<WeatherLocation, Never> { get }
}

protocol SearchViewModelProtocol: ThemeProviding {
    var inputs: SearchViewModelInputs { get }
    var outputs: SearchViewModelOutputs { get }
}

class SearchViewModel: SearchViewModelProtocol, SearchViewModelInputs, SearchViewModelOutputs, CoordinatesPresenting {
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let locationManager: LocationManager
    
    private var model: Search.Model = Search.Model()

    let theme: Theme
    let apiService: RequestExecuting
    
    var inputs: SearchViewModelInputs { return self }
    var outputs: SearchViewModelOutputs { return self }
    
    // Inputs
    let searchValue: CurrentValueSubject<String?, Never> = CurrentValueSubject(nil)
    let performSearch: PassthroughSubject<Void, Never> = PassthroughSubject()
    let animationDidStart: PassthroughSubject<Void, Never> = PassthroughSubject()
    let animationDidComplete: PassthroughSubject<Bool, Never> = PassthroughSubject()
    let locationHintTap: PassthroughSubject<Int, Never> = PassthroughSubject()
    let viewDidDisappear: PassthroughSubject<Void, Never> = PassthroughSubject()
    let searchByLocation: PassthroughSubject<Void, Never> = PassthroughSubject()
    let searchFieldDidBeginEditing: PassthroughSubject<Void, Never> = PassthroughSubject()
    let favoriteLocationDidSelect: PassthroughSubject<Int, Never> = PassthroughSubject()
    let favoriteLocationDidDelete: PassthroughSubject<Int, Never> = PassthroughSubject()
    
    // Outputs
    let isInteractiveAnimationEnabled: Bool
    
    private let _searchPlaceholder: CurrentValueSubject<String, Never> = CurrentValueSubject(NSLocalizedString("searchInputPlaceholder", comment: ""))
    let searchPlaceholder: AnyPublisher<NSAttributedString?, Never>
    
    private let _locationButtonTitle: CurrentValueSubject<DuotoneIconButton.ViewModel, Never> = CurrentValueSubject(DuotoneIconButton.ViewModel(icon: .location, title: NSLocalizedString("searchDeviceLocationButton", comment: "")))
    let locationButtonTitle: AnyPublisher<DuotoneIconButton.ViewModel, Never>
    
    private let _animationState: CurrentValueSubject<Search.AnimationState, Never> = CurrentValueSubject(.hidden)
    var animationState: Search.AnimationState {
        return _animationState.value
    }
    
    private let _searchHints: PassthroughSubject<Search.SearchHints?, Never> = PassthroughSubject()
    let searchHints: AnyPublisher<Search.SearchHints?, Never>
    
    private let _sceneDidHide: PassthroughSubject<Void, Never> = PassthroughSubject()
    let sceneDidHide: AnyPublisher<Void, Never>
    
    private let _sceneWillHide: PassthroughSubject<Void, Never> = PassthroughSubject()
    let sceneWillHide: AnyPublisher<Void, Never>
    
    private let _sceneDidAppear: PassthroughSubject<Void, Never> = PassthroughSubject()
    let sceneDidAppear: AnyPublisher<Void, Never>
    
    private let _favoriteLocations: CurrentValueSubject<[Search.Location.ViewModel], Never> = CurrentValueSubject([])
    private let _favorites: CurrentValueSubject<Search.Favorites.ViewModel, Never> = CurrentValueSubject(.none(""))
    let favorites: AnyPublisher<Search.Favorites.ViewModel, Never>
    
    private let _favoriteDeleteAlert: PassthroughSubject<Alert.ViewModel, Never> = PassthroughSubject()
    let favoriteDeleteAlert: AnyPublisher<Alert.ViewModel, Never>
    
    private let _favoriteDidDelete: PassthroughSubject<WeatherLocation, Never> = PassthroughSubject()
    let favoriteDidDelete: AnyPublisher<WeatherLocation, Never>
    
    init(apiService: RequestExecuting, theme: Theme, router: WeakRouter<AppRoute>, storage: FavoriteLocationStorageManaging, locationManager: LocationManager, isInteractiveAnimationEnabled: Bool) {
        self.theme = theme
        self.apiService = apiService
        self.locationManager = locationManager
        self.isInteractiveAnimationEnabled = isInteractiveAnimationEnabled
        
        // Outputs
        self.searchPlaceholder = _searchPlaceholder
            .map({ [theme] (text) in
                NSAttributedString(string: text, attributes: [
                    NSAttributedString.Key.font: theme.fonts.primary(style: .title2),
                    NSAttributedString.Key.foregroundColor: theme.colors.secondaryLabel
                ])
            }).asDriver(onErrorJustReturn: nil)
        
        self.locationButtonTitle = _locationButtonTitle.asDriver()
        self.searchHints = _searchHints.asDriver(onErrorJustReturn: nil)
        self.sceneDidHide = _sceneDidHide.eraseToAnyPublisher()
        self.sceneWillHide = _sceneWillHide.eraseToAnyPublisher()
        self.sceneDidAppear = _sceneDidAppear.eraseToAnyPublisher()
        self.favorites = _favorites.asDriver()
        self.favoriteDeleteAlert = _favoriteDeleteAlert.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        self.favoriteDidDelete = _favoriteDidDelete.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        
        let searchValue = self.performSearch
            .flatMap({ [searchValue] in
                searchValue.eraseToAnyPublisher()
            })
            .share()
        
        searchValue
            .sink(receiveValue: { [weak self] (searchTerm) in
                if let term = searchTerm, term.isEmpty == false {
                    self?._searchHints.send(.loading)
                } else {
                    self?._searchHints.send(nil)
                }
            })
            .store(in: &self.cancellables)

        let searchResults = searchValue
            .compactMap({ $0 })
            .filter({ !$0.isEmpty })
            .setFailureType(to: Error.self)
            .flatMap({ searchTerm in
                apiService.execute(request: APIResource.geo(location: searchTerm))
            })
            .tryMap({ try $0.map(to: [Search.Location.Response].self) })
            .share()

        self.animationDidComplete
            .sink(receiveValue: { [weak self] (finished) in
                self?.updateAnimationState(finished: finished)
            })
            .store(in: &self.cancellables)

        self.locationHintTap
            .compactMap({ [weak self] in
                self?.model.getHintLocation(at: $0)
            })
            .sink(receiveValue: { [weak self] (location) in
                self?._sceneWillHide.send(())
                
                router.route(to: .weather(location))
            })
            .store(in: &self.cancellables)

        self._animationState
            .dropFirst()
            .filter({ $0 == .hidden })
            .sink(receiveValue: { [weak self] _ in
                self?._sceneDidHide.send(())
            })
            .store(in: &self.cancellables)
        
        self._animationState
            .dropFirst()
            .removeDuplicates()
            .filter({ $0 == .visible })
            .map({ _ in })
            .assign(to: self._sceneDidAppear)
            .store(in: &self.cancellables)
        
        self.viewDidDisappear
            .assign(to: self._sceneDidHide)
            .store(in: &self.cancellables)
        
        self.favoriteLocationDidSelect
            .compactMap({ [weak self] in
                self?.model.getFavoriteLocation(at: $0)
            })
            .sink(receiveValue: { [weak self] (location) in
                self?._sceneWillHide.send(())
                
                router.route(to: .weather(location))
            })
            .store(in: &self.cancellables)
        
        let unfavorite = self.favoriteLocationDidDelete
            .map({ [weak self] (index) -> (Int, WeatherLocation?) in
                (index, self?.model.getFavoriteLocation(at: index))
            })
            .filter({ $0.1 != nil })
            .flatMap({ pair in
                storage.saveLocationFavoriteStatus(pair.1!, isFavorite: false)
                    .map({ _ in Optional(pair) })
                    .replaceError(with: nil)
            })
            .share()

        unfavorite
            .compactMap({ $0?.1 })
            .assign(to: self._favoriteDidDelete)
            .store(in: &self.cancellables)

        unfavorite
            .compactMap({ $0?.0 })
            .sink(receiveValue: { [weak self] (index) in
                self?.removeFavoriteLocation(at: index)
            })
            .store(in: &self.cancellables)

        unfavorite
            .filter({ $0 == nil })
            .compactMap({ [weak self] _ in
                self?.getFavoriteDeleteErrorAlert()
            })
            .assign(to: self._favoriteDeleteAlert)
            .store(in: &self.cancellables)
        
        // Look up locations based on the device location
        let searchByLocation = self.searchByLocation
            .handleEvents(receiveOutput: { [weak self] _ in
                self?._searchHints.send(.loading)
            })
            .flatMap({ [locationManager] in
                locationManager.currentLocation
            })
            .setFailureType(to: Error.self)
            .flatMap({ (location: CLLocation) in
                apiService.execute(request: APIResource.reverseGeo(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            })
            .tryMap({ try $0.map(to: [Search.Location.Response].self) })
            .share()
        
        // Single location found for the device location, show weather right away
        searchByLocation
            .replaceError(with: [])
            .filter({ $0.count == 1 })
            .compactMap({ $0.first })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (location) in
                self?._searchHints.send(nil)
                self?._sceneWillHide.send(())

                router.route(to: .weather(location))
            })
            .store(in: &self.cancellables)
        
        // Multiple locations found for the device location, show them in the search hints
        let multipleLocations = searchByLocation.filter({ $0.count > 1 })
        
        // Merge search results (via text input) and multiple locations found for device location, showing search hints
        Publishers.Merge(searchResults, multipleLocations)
            .map({ [weak self] in
                $0.compactMap {
                    self?.getLocation(response: $0)
                }
            })
            .map({ (cities) -> Search.SearchHints in
                if cities.isEmpty {
                    return Search.SearchHints.empty(message: NSLocalizedString("searchHintsNoResultsMessage", comment: ""))
                }
                return Search.SearchHints.results(cities: cities)
            })
            .replaceError(with: Search.SearchHints.error(message: NSLocalizedString("searchHintsErrorMessage", comment: "")))
            .receive(on: DispatchQueue.main)
            .assign(to: self._searchHints)
            .store(in: &self.cancellables)
        
        // Update model with the found locations
        searchResults
            .map { Optional($0) }
            .replaceError(with: [])
            .assign(to: \.value, on: self.model.hints)
            .store(in: &self.cancellables)
        
        // Clear search hints if showing error message and we focus into the search field
        self.searchFieldDidBeginEditing
            .flatMap({ [_searchHints] in
                _searchHints
            })
            .compactMap({ $0 })
            .filter({ (val: Search.SearchHints) -> Bool in
                if case Search.SearchHints.error = val {
                    return true
                }
                return false
            })
            .map({ _ in
                Optional<Search.SearchHints>.none
            })
            .assign(to: self._searchHints)
            .store(in: &self.cancellables)
        
        // Load favorites
        storage.loadFavoriteLocations()
            .handleEvents(receiveOutput: { [weak self] (locations: [WeatherLocation]) in
                self?.model.favorites.send(locations)
            })
            .compactMap({ [weak self] (locations: [WeatherLocation]) in
                locations.compactMap({
                    self?.getFavoriteLocation(response: $0)
                })
            })
            .replaceError(with: [])
            .assign(to: \.value, on: self._favoriteLocations)
            .store(in: &self.cancellables)
                
        self._favoriteLocations
            .map({ [weak self] (locations: [Search.Location.ViewModel]) -> Search.Favorites.ViewModel in
                if locations.isEmpty {
                    let message: String = NSLocalizedString("noFavoritesMessage", comment: "")
                    return .none(message)
                }

                let title: String = self?.getFavoritesTitle(count: locations.count) ?? ""
                return .saved(title, locations)
            })
            .replaceError(with: .none(NSLocalizedString("noFavoritesMessage", comment: "")))
            .assign(to: \.value, on: self._favorites)
            .store(in: &self.cancellables)
    }
    
    private func getLocation(response: Search.Location.Response) -> Search.Location.ViewModel {
        var title: String = response.name
        if let state = response.state, state.isEmpty == false {
            title = "\(title), \(state)"
        }
        
        let subtitle: String = self.getCoords(lat: response.lat, lon: response.lon)
        return Search.Location.ViewModel(flag: UIImage(named: response.country), title: title, subtitle: subtitle)
    }
    
    private func updateAnimationState(finished: Bool) {
        let newState: Search.AnimationState = finished ? self.animationState.opposite : self.animationState
        self._animationState.send(newState)
    }
    
    private func getFavoriteLocation(response: WeatherLocation) -> Search.Location.ViewModel {
        var title: String = response.name
        if let state = response.state, state.isEmpty == false {
            title = "\(title), \(state)"
        }
        
        let subtitle: String = self.getCoords(lat: response.lat, lon: response.lon)
        return Search.Location.ViewModel(flag: UIImage(named: response.country), title: title, subtitle: subtitle)
    }
    
    private func getFavoritesTitle(count: Int) -> String {
        let title: String = NSLocalizedString("numberOfFavoritesTitle", comment: "")
        return String.localizedStringWithFormat(title, count)
    }
    
    private func getFavoriteDeleteErrorAlert() -> Alert.ViewModel {
        let title: String = NSLocalizedString("locationFavoriteErrorTitle", comment: "")
        let message: String = NSLocalizedString("locationFavoriteErrorMessage", comment: "")
        let button: String = NSLocalizedString("okAlertButton", comment: "")
        return Alert.ViewModel(title: title, message: message, button: button)
    }
    
    private func removeFavoriteLocation(at index: Int) {
        self.model.removeFavoriteLocation(at: index)
        var locations: [Search.Location.ViewModel] = self._favoriteLocations.value
        locations.remove(at: index)
        self._favoriteLocations.send(locations)
    }

}
