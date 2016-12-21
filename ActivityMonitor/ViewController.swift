//
//  ViewController.swift
//  ActivityMonitor
//
//  Created by Justin Reid on 12/13/16.
//  Copyright © 2016 Justin Reid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var activityOptions: UICollectionView!
    @IBOutlet weak var filterText: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var currentActionLabel: UILabel!
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    private let activityFullList:Variable<[ActivityOption]> = Variable([ActivityOption(code:"Commute"), ActivityOption(code:"Work")])
    private let activityDisplayList:Variable<[ActivityOption]> = Variable([])
    private let currentActivity:Variable<ActivityOption?> = Variable(nil)
    private let gradient: CAGradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAddButtonState(enabled: false)
        
        activityOptions.register(UINib(nibName:"ActivityOptionCell", bundle:nil), forCellWithReuseIdentifier: "ActivityOptionCell")
        
        // Setup observers
        activityDisplayList.asObservable()
        .bindTo(activityOptions.rx.items(cellIdentifier: ActivityOptionCell.Identifier, cellType: ActivityOptionCell.self)) {
            row, option, cell in
            cell.configureWithOption(option: option)
        }
        .addDisposableTo(disposeBag)
        
        activityOptions.rx.modelSelected(ActivityOption.self).subscribe(onNext: {
            option in
            
            self.currentActivity.value = option
        })
        .addDisposableTo(disposeBag)
        
        
        
        
        
        // Filter the list
        filterText.rx.text.throttle(0.25, scheduler: MainScheduler.instance).subscribe(onNext: {
            currentText in
            
            self.buildDisplayList(potentialFilter: currentText)
        })
        .addDisposableTo(disposeBag)
        
        
        // Update title label
        currentActivity.asObservable().subscribe(onNext: {
            current in
            
            self.currentActionLabel.text = current?.code
            
            let botColor: UIColor = UIColor.white
            let topColor: UIColor = UIColor(hue: current?.getHue() ?? 0, saturation: 0.1, brightness: 1, alpha: 1)
            
            
            self.gradient.colors = [topColor.cgColor, botColor.cgColor]
            self.gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            self.gradient.endPoint = CGPoint(x:0.0, y: 0.2)
            
        })
        .addDisposableTo(disposeBag)
        
        setupGradient()
    }
    
    
    func setupGradient() {
        gradient.frame = self.view.bounds
        self.view.layer.insertSublayer(gradient, at:0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func buildDisplayList(potentialFilter: String?) {
        if let filter = potentialFilter?.lowercased(), !filter.isEmpty {
            // First element is "create new"
            setAddButtonState(enabled: true)
            
            // Real options
            activityDisplayList.value = activityFullList.value.filter({
                $0.code.lowercased().range(of: filter) != nil
            })
        } else {
            setAddButtonState(enabled: false)
            activityDisplayList.value = activityFullList.value
        }
    }
    
    func setAddButtonState(enabled: Bool) {
        if enabled && addButton.isHidden {
            addButton.isHidden = false;
            addButton.alpha = 0;
            
            UIView.animate(withDuration: 0.25, animations: {
                self.addButton.alpha = (CGFloat(1.0))
                
                var newSize = self.filterText.frame
                newSize.size.width = self.addButton.frame.origin.x - newSize.origin.x - 16
                self.filterText.frame = newSize
            }, completion: nil)
        } else if !enabled && !addButton.isHidden {
            addButton.isHidden = true;
            addButton.alpha = 1;
            
            UIView.animate(withDuration: 0.25, animations: {
                self.addButton.alpha = (CGFloat(0.0))
                
                var newSize = self.filterText.frame
                newSize.size.width = self.addButton.frame.maxX - newSize.origin.x
                self.filterText.frame = newSize
            }, completion: nil)
        }
    }
    
    @IBAction func addActivity(){
        if let newCode:String = filterText.text, !newCode.isEmpty {
            activityFullList.value.append(ActivityOption(code:newCode))
            
            filterText.text = ""
            filterText.resignFirstResponder()
        }
    }
}

class ActivityOptionCell: UICollectionViewCell {
    static let Identifier = "ActivityOptionCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var bigTitle: UILabel!
    
    func configureWithOption(option: ActivityOption) {
        imageView.isHidden = false;
        title.isHidden = false
        bigTitle.isHidden = false;
        
        if let image = ActivityOption.Icons[option.code] {
            imageView.image = image
            title.text = option.code
            bigTitle.isHidden = true
        } else {
            imageView.isHidden = true
            title.isHidden = true
            bigTitle.text = option.code
        }
        
        
        backgroundColor = UIColor.init(hue: option.getHue(), saturation: 0.1, brightness: 1, alpha: 1)
        
        layer.cornerRadius = 8.0
//        layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
//        layer.shadowRadius = 2;
//        layer.shadowOpacity = 0.1;
//        layer.masksToBounds = false
    }
    
}

class ActivityOption {
    static let Icons: [String:UIImage] = [
        "Commute": UIImage(named:"Commute")!,
        "Work": UIImage(named:"Work")!
    ]
    
    public let code: String
    
    init(code: String) {
        self.code = code
    }
    
    public func getHue() -> CGFloat {
        return (CGFloat)(code.hash % 100) / (CGFloat(100.0))
    }
}
