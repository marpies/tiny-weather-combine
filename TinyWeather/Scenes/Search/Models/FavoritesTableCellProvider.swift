//
//  FavoritesTableCellProvider.swift
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

struct FavoritesTableCellProvider {
    
    private let cellId: String = "favorite"
    private let theme: Theme
    
    init(tableView: UITableView, theme: Theme) {
        self.theme = theme
        
        tableView.register(FavoriteLocationTableViewCell.self, forCellReuseIdentifier: self.cellId)
    }
    
    func cellFactory(tableView: UITableView, indexPath: IndexPath, viewModel: Search.Location.ViewModel) -> UITableViewCell {
        let cell: FavoriteLocationTableViewCell = tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath) as! FavoriteLocationTableViewCell
        
        cell.theme = self.theme
        cell.update(viewModel: viewModel)
        
        return cell
    }
    
}
