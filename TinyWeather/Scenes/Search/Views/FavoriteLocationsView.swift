//
//  FavoriteLocationsView.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import UIKit
import TWThemes
import SnapKit
import RxSwift
import RxRelay
import RxGesture

class FavoriteLocationsView: UIView, UITableViewDelegate {
    
    private let theme: Theme

    private var messageLabel: UILabel?
    private var titleLabel: UILabel?
    private var tableShadow: UIView?
    private var dataSource: FavoritesTableDataSource?
    private var disposeBag: DisposeBag?
    
    private(set) var tableView: UITableView?
    
    private let locations: BehaviorRelay<[Search.Location.ViewModel]> = BehaviorRelay(value: [])
    
    private let _tableViewDidScroll: PublishRelay<Void> = PublishRelay()
    var tableViewDidScroll: Observable<Void> {
        return _tableViewDidScroll.asObservable()
    }
    
    private let _locationDidSelect: PublishRelay<Int> = PublishRelay()
    var locationDidSelect: Observable<Int> {
        return _locationDidSelect.asObservable()
    }
    
    private let _locationDidDelete: PublishRelay<Int> = PublishRelay()
    var locationDidDelete: Observable<Int> {
        return _locationDidDelete.asObservable()
    }
    
    var panGesture: UIGestureRecognizer? {
        return self.tableView?.panGestureRecognizer
    }

    init(theme: Theme) {
        self.theme = theme
        
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let shadow = self.tableShadow {
            shadow.layer.shadowPath = CGPath(roundedRect: shadow.bounds, cornerWidth: 8, cornerHeight: 8, transform: nil)
        }
    }
    
    //
    // MARK: - Public
    //
    
    func update(viewModel: Search.Favorites.ViewModel) {
        switch viewModel {
        case .none(let message):
            self.showMessage(message)
        case .saved(let title, let locations):
            self.showFavorites(title: title, locations: locations)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func showMessage(_ message: String) {
        if self.messageLabel == nil {
            self.messageLabel = UILabel()
            self.messageLabel.map { label in
                label.font = self.theme.fonts.primary(style: .body)
                label.textColor = self.theme.colors.label
                label.numberOfLines = 0
                label.textAlignment = .center
                label.alpha = 0
                self.addSubview(label)
                label.snp.makeConstraints { make in
                    make.leading.trailing.top.equalToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                }
                
                UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseOut, animations: {
                    label.alpha = 1
                }, completion: nil)
            }
        }
        
        self.messageLabel?.text = message
        
        self.locations.accept([])
        
        self.disposeBag = nil
        
        if let table = self.tableView, let label = self.titleLabel, let tableShadow = self.tableShadow {
            self.tableView = nil
            self.titleLabel = nil
            self.tableShadow = nil
            
            UIView.animate(withDuration: 0.3, animations: {
                table.alpha = 0
                label.alpha = 0
                tableShadow.alpha = 0
            }, completion: { _ in
                table.removeFromSuperview()
                label.removeFromSuperview()
                tableShadow.removeFromSuperview()
            })
        }
    }
    
    private func showFavorites(title: String, locations: [Search.Location.ViewModel]) {
        if self.tableView == nil {
            self.titleLabel = UILabel()
            self.titleLabel.map { label in
                label.font = self.theme.fonts.primary(style: .title1)
                label.textColor = self.theme.colors.secondaryLabel
                self.addSubview(label)
                label.snp.makeConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(8)
                    make.top.equalToSuperview()
                }
            }
            
            self.tableView = UITableView(frame: .zero, style: .plain)
            self.tableView.map { table in
                table.allowsSelection = true
                table.allowsMultipleSelection = false
                table.showsVerticalScrollIndicator = false
                table.rowHeight = 60
                table.backgroundColor = .clear
                table.separatorColor = self.theme.colors.separator
                table.delegate = self
                self.addSubview(table)
                table.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.height.equalTo(4 * 60)
                    make.top.equalTo(self.titleLabel!.snp.bottom).offset(8)
                }
                
                self.tableShadow = UIView()
                self.tableShadow.map { view in
                    view.layer.shadowColor = self.theme.colors.shadow.cgColor
                    view.layer.shadowOffset = CGSize(width: 0, height: 10)
                    view.layer.shadowRadius = 20
                    view.layer.shadowOpacity = 0.15
                    view.layer.cornerRadius = 8
                    view.backgroundColor = self.theme.colors.secondaryBackground
                    self.insertSubview(view, belowSubview: table)
                    view.snp.makeConstraints { make in
                        make.edges.equalTo(table)
                    }
                }
                
                self.dataSource = FavoritesTableDataSource(tableView: table, theme: self.theme)
                
                self.disposeBag = DisposeBag()
                self.disposeBag.map { bag in
                    self.locations
                        .bind(to: self.dataSource!.rx.viewModel)
                        .disposed(by: bag)
                    
                    table.panGestureRecognizer.rx.event
                        .filter({ $0.state == .began })
                        .map({ _ in })
                        .bind(to: self._tableViewDidScroll)
                        .disposed(by: bag)
                }
            }
        }
        
        self.titleLabel?.text = title
        self.locations.accept(locations)
        
        self.messageLabel?.removeFromSuperview()
        self.messageLabel = nil
    }
    
    //
    // MARK: - Table view delegate
    //
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self._locationDidSelect.accept(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title: String = NSLocalizedString("favoriteLocationRemoveButton", comment: "")
        let action: UIContextualAction = UIContextualAction(style: .destructive, title: title) { [weak self] (_, _, completion) in
            self?._locationDidDelete.accept(indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
}
