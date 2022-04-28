//
//  SetupViewController.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import UIKit
import SnapKit
import RxSwift

class SetupViewController: UIViewController {
    
    private let disposeBag: DisposeBag = DisposeBag()
    private let imageView: UIImageView = UIImageView()
    
    private let viewModel: SetupViewModelProtocol

    init(viewModel: SetupViewModelProtocol) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = self.viewModel.theme.colors.background
        
        self.bindViewModel()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.horizontalSizeClass != self.traitCollection.horizontalSizeClass {
            self.setupConstraints()
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func displayLaunchImage(named name: String) {
        self.imageView.image = UIImage(named: name)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.backgroundColor = self.viewModel.theme.colors.background
        self.view.addSubview(self.imageView)
        
        self.setupConstraints()
        
        UIView.animateKeyframes(withDuration: 2 / 3, delay: 0.5, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self.imageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                self.imageView.transform = .identity
            })
        }, completion: { _ in
            let inputs: SetupViewModelInputs = self.viewModel.inputs
            inputs.viewDidLoad.accept(())
        })
    }
    
    private func setupConstraints() {
        let isRegular: Bool = self.traitCollection.horizontalSizeClass == .regular
        
        self.imageView.snp.remakeConstraints { make in
            make.centerX.equalTo(self.view.safeAreaLayoutGuide)
            make.centerY.equalTo(self.view.safeAreaLayoutGuide).multipliedBy(0.9)
            
            let widthMultiplier: CGFloat = isRegular ? 0.2 : 0.4
            make.width.equalToSuperview().multipliedBy(widthMultiplier)
            make.height.equalTo(self.imageView.snp.width).multipliedBy(0.8)
        }
    }

    //
    // MARK: - View model bindable
    //

    private func bindViewModel() {
        let outputs: SetupViewModelOutputs = self.viewModel.outputs
        
        outputs.launchImageName
            .subscribe(onNext: { [weak self] (name) in
                self?.displayLaunchImage(named: name)
            })
            .disposed(by: self.disposeBag)
    }
    
}
