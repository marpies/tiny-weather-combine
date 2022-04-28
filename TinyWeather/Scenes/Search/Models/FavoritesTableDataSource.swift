//
//  FavoritesTableDataSource.swift
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

class FavoritesTableDataSource: UITableViewDiffableDataSource<Int, Search.Location.ViewModel> {

    private var viewModel: [Search.Location.ViewModel] = []

    init(tableView: UITableView, theme: Theme) {
        let cellProvider: FavoritesTableCellProvider = FavoritesTableCellProvider(tableView: tableView, theme: theme)
        
        super.init(tableView: tableView, cellProvider: cellProvider.cellFactory)
        
        self.defaultRowAnimation = .fade
        
        tableView.dataSource = self
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Required for swipe actions to work on the table view on iOS 14 and below
        return true
    }

    func update(viewModel: [Search.Location.ViewModel]) {
        self.viewModel = viewModel

        var snapshot = self.snapshot()
        if snapshot.numberOfSections > 0 {
            snapshot.deleteSections([0])
        }
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel, toSection: 0)
        self.apply(snapshot, animatingDifferences: true, completion: nil)
    }

}
