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
import RxSwift
import RxCocoa
import UIKit
import TWThemes
import TWRoutes
import TWModels
import CoreLocation

protocol SearchViewModelInputs {
    var animationDidStart: PublishRelay<Void> { get }
    var animationDidComplete: PublishRelay<Bool> { get }
    var viewDidDisappear: PublishRelay<Void> { get }
    var searchFieldDidBeginEditing: PublishRelay<Void> { get }
    
    var searchValue: BehaviorRelay<String?> { get }
    var performSearch: PublishSubject<Void> { get }
    var locationHintTap: PublishRelay<Int> { get }
    var searchByLocation: PublishRelay<Void> { get }
    var favoriteLocationDidSelect: PublishRelay<Int> { get }
    var favoriteLocationDidDelete: PublishRelay<Int> { get }
}

protocol SearchViewModelOutputs {
    var searchPlaceholder: Driver<NSAttributedString?> { get }
    var locationButtonTitle: Driver<DuotoneIconButton.ViewModel> { get }
    var animationState: Search.AnimationState { get }
    var searchHints: Driver<Search.SearchHints?> { get }
    var sceneDidHide: Observable<Void> { get }
    var sceneWillHide: Observable<Void> { get }
    var sceneDidAppear: Observable<Void> { get }
    var isInteractiveAnimationEnabled: Bool { get }
    var favorites: Driver<Search.Favorites.ViewModel> { get }
    var favoriteDeleteAlert: Signal<Alert.ViewModel> { get }
    var favoriteDidDelete: Signal<WeatherLocation> { get }
}

protocol SearchViewModelProtocol: ThemeProviding {
    var inputs: SearchViewModelInputs { get }
    var outputs: SearchViewModelOutputs { get }
}

class SearchViewModel: SearchViewModelProtocol, SearchViewModelInputs, SearchViewModelOutputs, CoordinatesPresenting {
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    // todo should be abstracted away for mocking
    private let locationManager: CLLocationManager = CLLocationManager()
    
    private var model: Search.Model = Search.Model()

    let theme: Theme
    let apiService: RequestExecuting
    
    var inputs: SearchViewModelInputs { return self }
    var outputs: SearchViewModelOutputs { return self }
    
    // Inputs
    let searchValue: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let performSearch: PublishSubject<Void> = PublishSubject()
    let animationDidStart: PublishRelay<Void> = PublishRelay()
    let animationDidComplete: PublishRelay<Bool> = PublishRelay()
    let locationHintTap: PublishRelay<Int> = PublishRelay()
    let viewDidDisappear: PublishRelay<Void> = PublishRelay()
    let searchByLocation: PublishRelay<Void> = PublishRelay()
    let searchFieldDidBeginEditing: PublishRelay<Void> = PublishRelay()
    let favoriteLocationDidSelect: PublishRelay<Int> = PublishRelay()
    let favoriteLocationDidDelete: PublishRelay<Int> = PublishRelay()
    
    // Outputs
    let isInteractiveAnimationEnabled: Bool
    
    private let _searchPlaceholder: BehaviorRelay<String> = BehaviorRelay(value: NSLocalizedString("searchInputPlaceholder", comment: ""))
    let searchPlaceholder: Driver<NSAttributedString?>
    
    private let _locationButtonTitle: BehaviorRelay<DuotoneIconButton.ViewModel> = BehaviorRelay(value: DuotoneIconButton.ViewModel(icon: .location, title: NSLocalizedString("searchDeviceLocationButton", comment: "")))
    let locationButtonTitle: Driver<DuotoneIconButton.ViewModel>
    
    private let _animationState: BehaviorRelay<Search.AnimationState> = BehaviorRelay(value: .hidden)
    var animationState: Search.AnimationState {
        return _animationState.value
    }
    
    private let _searchHints: PublishRelay<Search.SearchHints?> = PublishRelay()
    let searchHints: Driver<Search.SearchHints?>
    
    private let _sceneDidHide: PublishRelay<Void> = PublishRelay()
    let sceneDidHide: Observable<Void>
    
    private let _sceneWillHide: PublishRelay<Void> = PublishRelay()
    let sceneWillHide: Observable<Void>
    
    private let _sceneDidAppear: PublishRelay<Void> = PublishRelay()
    let sceneDidAppear: Observable<Void>
    
    private let _favoriteLocations: BehaviorRelay<[Search.Location.ViewModel]> = BehaviorRelay(value: [])
    private let _favorites: BehaviorRelay<Search.Favorites.ViewModel> = BehaviorRelay(value: .none(""))
    let favorites: Driver<Search.Favorites.ViewModel>
    
    private let _favoriteDeleteAlert: PublishRelay<Alert.ViewModel> = PublishRelay()
    let favoriteDeleteAlert: Signal<Alert.ViewModel>
    
    private let _favoriteDidDelete: PublishRelay<WeatherLocation> = PublishRelay()
    let favoriteDidDelete: Signal<WeatherLocation>
    
    init(apiService: RequestExecuting, theme: Theme, router: WeakRouter<AppRoute>, storage: FavoriteLocationStorageManaging, isInteractiveAnimationEnabled: Bool) {
        self.theme = theme
        self.apiService = apiService
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
        self.sceneDidHide = _sceneDidHide.asObservable()
        self.sceneWillHide = _sceneWillHide.asObservable()
        self.sceneDidAppear = _sceneDidAppear.asObservable()
        self.favorites = _favorites.asDriver()
        self.favoriteDeleteAlert = _favoriteDeleteAlert.asSignal()
        self.favoriteDidDelete = _favoriteDidDelete.asSignal()
        
        self.performSearch.withLatestFrom(self.searchValue)
            .subscribe(onNext: { [weak self] (searchTerm) in
                if let term = searchTerm, term.isEmpty == false {
                    self?._searchHints.accept(.loading)
                } else {
                    self?._searchHints.accept(nil)
                }
            })
            .disposed(by: self.disposeBag)

        let searchResults = self.performSearch.withLatestFrom(self.searchValue)
            .compactMap({ $0 })
            .filter({ !$0.isEmpty })
            .flatMapLatest({ searchTerm in
                apiService.execute(request: APIResource.geo(location: searchTerm))
            })
            .map({ try $0.map(to: [Search.Location.Response].self) })
            .share()

        self.animationDidComplete
            .subscribe(onNext: { [weak self] (finished) in
                self?.updateAnimationState(finished: finished)
            })
            .disposed(by: self.disposeBag)

        self.locationHintTap
            .asObservable()
            .compactMap({ [weak self] in
                self?.model.getHintLocation(at: $0)
            })
            .subscribe(onNext: { [weak self] (location) in
                self?._sceneWillHide.accept(())
                
                router.route(to: .weather(location))
            })
            .disposed(by: self.disposeBag)

        self._animationState
            .skip(1)
            .filter({ $0 == .hidden })
            .subscribe(onNext: { [weak self] _ in
                self?._sceneDidHide.accept(())
            })
            .disposed(by: self.disposeBag)
        
        self._animationState
            .skip(1)
            .distinctUntilChanged()
            .filter({ $0 == .visible })
            .map({ _ in })
            .bind(to: _sceneDidAppear)
            .disposed(by: self.disposeBag)
        
        self.viewDidDisappear
            .bind(to: self._sceneDidHide)
            .disposed(by: self.disposeBag)
        
        self.favoriteLocationDidSelect
            .compactMap({ [weak self] in
                self?.model.getFavoriteLocation(at: $0)
            })
            .subscribe(onNext: { [weak self] (location) in
                self?._sceneWillHide.accept(())
                
                router.route(to: .weather(location))
            })
            .disposed(by: self.disposeBag)
        
        let unfavorite = self.favoriteLocationDidDelete
            .map({ [weak self] (index) -> (Int, WeatherLocation?) in
                (index, self?.model.getFavoriteLocation(at: index))
            })
            .filter({ $0.1 != nil })
            .flatMap({ pair in
                storage.saveLocationFavoriteStatus(pair.1!, isFavorite: false)
                    .map({ _ in Optional(pair) })
                    .catchAndReturn(nil)
            })
            .share()
        
        unfavorite
            .compactMap({ $0?.1 })
            .bind(to: self._favoriteDidDelete)
            .disposed(by: self.disposeBag)
        
        unfavorite
            .compactMap({ $0?.0 })
            .subscribe(onNext: { [weak self] (index) in
                self?.removeFavoriteLocation(at: index)
            })
            .disposed(by: self.disposeBag)
                
        unfavorite
            .filter({ $0 == nil })
            .compactMap({ [weak self] _ in
                self?.getFavoriteDeleteErrorAlert()
            })
            .bind(to: self._favoriteDeleteAlert)
            .disposed(by: self.disposeBag)
        
        // Look up locations based on the device location
        let searchByLocation = self.searchByLocation
            .flatMapLatest({
                self.locationManager.rx.getCurrentLocation()
            })
            .do(onNext: { [weak self] _ in
                self?._searchHints.accept(.loading)
            })
            .flatMapLatest({ location in
                apiService.execute(request: APIResource.reverseGeo(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            })
            .map({ try $0.map(to: [Search.Location.Response].self) })
            .share()
        
        // Single location found for the device location, show weather right away
        searchByLocation
            .catchAndReturn([])
            .filter({ $0.count == 1 })
            .compactMap({ $0.first })
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (location) in
                self?._searchHints.accept(nil)
                self?._sceneWillHide.accept(())
                
                router.route(to: .weather(location))
            })
            .disposed(by: self.disposeBag)
        
        // Multiple locations found for the device location, show them in the search hints
        let multipleLocations = searchByLocation.filter({ $0.count > 1 })
        
        // Merge search results (via text input) and multiple locations found for device location, showing search hints
        Observable.merge(searchResults, multipleLocations)
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
            .catchAndReturn(.error(message: NSLocalizedString("searchHintsErrorMessage", comment: "")))
            .observe(on: MainScheduler.instance)
            .bind(to: self._searchHints)
            .disposed(by: self.disposeBag)
        
        // Update model with the found locations
        Observable.merge(searchResults, searchByLocation)
            .catchAndReturn([])
            .bind(to: self.model.hints)
            .disposed(by: self.disposeBag)
        
        // Clear search hints if showing error message and we focus into the search field
        self.searchFieldDidBeginEditing.withLatestFrom(self._searchHints)
            .compactMap({ $0 })
            .filter({ val in
                if case Search.SearchHints.error = val {
                    return true
                }
                return false
            })
            .subscribe(onNext: { [weak self] _ in
                self?._searchHints.accept(nil)
            })
            .disposed(by: self.disposeBag)
        
        // Load favorites
        storage.loadFavoriteLocations()
            .do(onSuccess: { [weak self] (locations: [WeatherLocation]) in
                self?.model.favorites.accept(locations)
            })
            .compactMap({ [weak self] (locations: [WeatherLocation]) in
                locations.compactMap({
                    self?.getFavoriteLocation(response: $0)
                })
            })
            .catchAndReturn([])
            .asObservable()
            .bind(to: self._favoriteLocations)
            .disposed(by: self.disposeBag)
                
        self._favoriteLocations
            .map({ [weak self] (locations: [Search.Location.ViewModel]) -> Search.Favorites.ViewModel in
                if locations.isEmpty {
                    let message: String = NSLocalizedString("noFavoritesMessage", comment: "")
                    return .none(message)
                }

                let title: String = self?.getFavoritesTitle(count: locations.count) ?? ""
                return .saved(title, locations)
            })
            .catchAndReturn(.none(NSLocalizedString("noFavoritesMessage", comment: "")))
            .asObservable()
            .bind(to: self._favorites)
            .disposed(by: self.disposeBag)
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
        self._animationState.accept(newState)
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
        self._favoriteLocations.accept(locations)
    }

}
