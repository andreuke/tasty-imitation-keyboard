//
//  Phrase.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import SQLite

class Phrases: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var NavBar: UINavigationItem!
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView?
    @IBOutlet var effectsView: UIVisualEffectView?
    @IBOutlet var backButton: UIButton?
    @IBOutlet var settingsLabel: UILabel?
    @IBOutlet var pixelLine: UIView?
    
    @IBOutlet weak var editName: UIBarButtonItem!
    var editPhraseCallBack: (String) -> ()
    var onClickCallBack: (String) -> ()
    var oldEditPhrase:String = "" //used for editing purposes
    override var darkMode: Bool {
        didSet {
            self.updateAppearance(darkMode)
        }
    }
    
    let cellBackgroundColorDark = UIColor.white.withAlphaComponent(CGFloat(0.25))
    let cellBackgroundColorLight = UIColor.white.withAlphaComponent(CGFloat(1))
    let cellLabelColorDark = UIColor.white
    let cellLabelColorLight = UIColor.black
    let cellLongLabelColorDark = UIColor.lightGray
    let cellLongLabelColorLight = UIColor.gray
    // TODO: these probably don't belong here, and also need to be localized
    var phrasesList: [(String, [String])]?
    
    required init(onClickCallBack: @escaping (String)->(), editCallback:@escaping (String)->(), globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        self.editPhraseCallBack = editCallback
        self.onClickCallBack = onClickCallBack
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.loadNib()
        let phrases: [String] = Database().getPhrases()
        self.NavBar.title = "Saved Phrases"
        self.phrasesList = [("Phrases", phrases)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool, outputFunc: () -> Void) {
        fatalError("init(globalColors:darkMode:solidColorMode:outputFunc:) has not been implemented")
    }
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        fatalError("init(globalColors:darkMode:solidColorMode:) has not been implemented")
    }

    
    func loadNib() {
        let assets = Bundle(for: type(of: self)).loadNibNamed("Phrases", owner: self, options: nil)
        
        if (assets?.count)! > 0 {
            if let rootView = assets?.first as? UIView {
                rootView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(rootView)
                
                let left = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
                let top = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
                let bottom = NSLayoutConstraint(item: rootView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
                
                self.addConstraint(left)
                self.addConstraint(right)
                self.addConstraint(top)
                self.addConstraint(bottom)
            }
        }
        self.tableView?.register(PhraseTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView?.estimatedRowHeight = 44;
        self.tableView?.rowHeight = UITableViewAutomaticDimension;
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(Phrases.longPressGestureRecognized(_:)))
        self.tableView?.addGestureRecognizer(longpress)
        
        // XXX: this is here b/c a totally transparent background does not support scrolling in blank areas
        self.tableView?.backgroundColor = UIColor.white.withAlphaComponent(0.01)
        
        self.updateAppearance(self.darkMode)
    }
    
    //drag and drop code
    
    func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        let indexPath = tableView?.indexPathForRow(at: locationInView)
        
        struct My {
            static var cellSnapshot : UIView? = nil
            static var cellIsAnimating : Bool = false
            static var cellNeedToShow : Bool = false
        }
        struct Path {
            static var initialIndexPath : IndexPath? = nil
        }
        
        switch state {
        case UIGestureRecognizerState.began:
            if indexPath != nil {
                Path.initialIndexPath = indexPath
                let cell = tableView?.cellForRow(at: indexPath!) as UITableViewCell!
                My.cellSnapshot  = snapshotOfCell(cell!)
                
                var center = cell?.center
                My.cellSnapshot!.center = center!
                My.cellSnapshot!.alpha = 0.0
                tableView?.addSubview(My.cellSnapshot!)
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    center?.y = locationInView.y
                    My.cellIsAnimating = true
                    My.cellSnapshot!.center = center!
                    My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    My.cellSnapshot!.alpha = 0.98
                    cell?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    if finished {
                        My.cellIsAnimating = false
                        if My.cellNeedToShow {
                            My.cellNeedToShow = false
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                                cell?.alpha = 1
                            })
                        } else {
                            cell?.isHidden = true
                        }
                    }
                })
            }
            
        case UIGestureRecognizerState.changed:
            if My.cellSnapshot != nil {
                var center = My.cellSnapshot!.center
                center.y = locationInView.y
                My.cellSnapshot!.center = center
                
                if ((indexPath != nil) && (indexPath != Path.initialIndexPath)) {
                
                    self.phrasesList![0].1.insert(self.phrasesList![0].1.remove(at: Path.initialIndexPath!.row), at: indexPath!.row)
                    let phrase = self.phrasesList![0].1[indexPath!.row]
                    let oldRow = Path.initialIndexPath!.row
                    let newRow = indexPath!.row
                    //itemsArray.insert(itemsArray.remove(at: Path.initialIndexPath!.row), at: indexPath!.row)
                    tableView?.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                    Path.initialIndexPath = indexPath
                }
            }
        /*case UIGestureRecognizerState.ended:
            if indexPath != nil {
                let phrase = self.phrasesList![0].1[indexPath!.row]
                let newRow = indexPath!.row
                Database().reorderPhrase(phrase: phrase, newNum: newRow)
            }*/
            
            
        default:
            if Path.initialIndexPath != nil {
                let cell = tableView?.cellForRow(at: Path.initialIndexPath!) as UITableViewCell!
                if My.cellIsAnimating {
                    My.cellNeedToShow = true
                } else {
                    cell?.isHidden = false
                    cell?.alpha = 0.0
                }
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    My.cellSnapshot!.center = (cell?.center)!
                    My.cellSnapshot!.transform = CGAffineTransform.identity
                    My.cellSnapshot!.alpha = 0.0
                    cell?.alpha = 1.0
                    
                }, completion: { (finished) -> Void in
                    if finished {
                        Path.initialIndexPath = nil
                        My.cellSnapshot!.removeFromSuperview()
                        My.cellSnapshot = nil
                        let phrase = self.phrasesList![0].1[indexPath!.row]
                        let newRow = indexPath!.row
                        Database().reorderPhrase(phrase: phrase, newRowNum: newRow)
                    }
                })
            }
        }
    }
    
    func snapshotOfCell(_ inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    //table functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.phrasesList!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.phrasesList![section].1.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == (self.phrasesList?.count)! - 1 {
            return 50
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.phrasesList?[section].0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? PhraseTableViewCell {
            let key = self.phrasesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
            
            if cell.sw.allTargets.count == 0 {
                cell.sw.addTarget(self, action: #selector(Phrases.toggleSetting(_:)), for: UIControlEvents.valueChanged)
            }
            

            cell.label.setTitle(key!, for: .normal)
            cell.label.addTarget(self, action: #selector(clickCallback(_:)), for: .touchUpInside)
            cell.longLabel.text = nil
            
            cell.backgroundColor = (self.darkMode ? cellBackgroundColorDark : cellBackgroundColorLight)
            cell.label.setTitleColor((self.darkMode ? cellLabelColorDark : cellLabelColorLight), for: UIControlState.normal)
            //cell.label.textColor = (self.darkMode ? cellLabelColorDark : cellLabelColorLight)
            cell.longLabel.textColor = (self.darkMode ? cellLongLabelColorDark : cellLongLabelColorLight)
            //cell.editingStyle = .delete
            cell.changeConstraints()
            
            return cell
        }
        else {
            assert(false, "this is a bad thing that just happened")
            return UITableViewCell()
        }
    }
    
    func updateAppearance(_ dark: Bool) {
        if dark {
            self.effectsView?.effect
            let blueColor = UIColor(red: 135/CGFloat(255), green: 206/CGFloat(255), blue: 250/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
            self.backButton?.setTitleColor(blueColor, for: UIControlState())
            self.settingsLabel?.textColor = UIColor.white
            if let visibleCells = self.tableView?.visibleCells {
                for cell in visibleCells {
                    cell.backgroundColor = cellBackgroundColorDark
                    let label = cell.viewWithTag(2) as? UILabel
                    label?.textColor = cellLabelColorDark
                    let longLabel = cell.viewWithTag(3) as? UITextView
                    longLabel?.textColor = cellLongLabelColorDark
                }
            }
        }
        else {
            let blueColor = UIColor(red: 0/CGFloat(255), green: 122/CGFloat(255), blue: 255/CGFloat(255), alpha: 1)
            self.pixelLine?.backgroundColor = blueColor.withAlphaComponent(CGFloat(0.5))
            self.backButton?.setTitleColor(blueColor, for: UIControlState())
            self.settingsLabel?.textColor = UIColor.gray
            
            if let visibleCells = self.tableView?.visibleCells {
                for cell in visibleCells {
                    cell.backgroundColor = cellBackgroundColorLight
                    let label = cell.viewWithTag(2) as? UILabel
                    label?.textColor = cellLabelColorLight
                    let longLabel = cell.viewWithTag(3) as? UITextView
                    longLabel?.textColor = cellLongLabelColorLight
                }
            }
        }
    }
    
    func toggleSetting(_ sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = self.tableView?.indexPath(for: cell) {
                let key = self.phrasesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
                UserDefaults.standard.set(sender.isOn, forKey: key!)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            //self.phrasesList![0].1.remove(at: indexPath.row)
            //Database().removephrase(target_profile: "Default", data_source: (self.phrasesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!)
            Database().deletePhrase(phrase: (self.phrasesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!)
            
            self.reloadData()
        }
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            self.editPhraseCallBack((self.phrasesList?[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row])!)
        }

        
        return [delete, edit]
    }
    
    func reloadData() {
        let phrases: [String] = Database().getPhrases()
        self.phrasesList = [("Phrases", phrases)]
        tableView?.reloadData()
    }
    
    func clickCallback(_ sender:UIButton) {
        print("i was clicked")
        self.onClickCallBack(sender.titleLabel!.text!)
    }
    
}

class PhraseTableViewCell: UITableViewCell {
    
    var sw: UIButton
    var label: UIButton
    var longLabel: UITextView
    var constraintsSetForLongLabel: Bool
    var cellConstraints: [NSLayoutConstraint]
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.sw = UIButton()
        self.label = UIButton()
        self.longLabel = UITextView()
        self.cellConstraints = []
        
        self.constraintsSetForLongLabel = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.sw.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.longLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.longLabel.text = nil
        self.longLabel.isScrollEnabled = false
        self.longLabel.isSelectable = false
        self.longLabel.backgroundColor = UIColor.clear
        
        self.sw.tag = 1
        self.label.tag = 2
        self.longLabel.tag = 3
        
        self.addSubview(self.sw)
        self.addSubview(self.label)
        self.addSubview(self.longLabel)
        
        self.addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addConstraints() {
        let margin: CGFloat = 8
        let sideMargin = margin * 2
        
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: margin)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            let left = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
            let right = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
            let top = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: margin)
            let bottom = NSLayoutConstraint(item: longLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -margin)
            
            self.addConstraint(left)
            self.addConstraint(right)
            self.addConstraint(top)
            self.addConstraint(bottom)
            
            self.cellConstraints += [switchSide, switchTop, labelSide, labelCenter, left, right, top, bottom]
            
            self.constraintsSetForLongLabel = true
        }
        else {
            let switchSide = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -sideMargin)
            let switchTop = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: margin)
            let switchBottom = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -margin)
            let labelSide = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: sideMargin)
            let labelCenter = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sw, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
            
            self.addConstraint(switchSide)
            self.addConstraint(switchTop)
            self.addConstraint(switchBottom)
            self.addConstraint(labelSide)
            self.addConstraint(labelCenter)
            
            self.cellConstraints += [switchSide, switchTop, switchBottom, labelSide, labelCenter]
            
            self.constraintsSetForLongLabel = false
        }
    }
    
    // XXX: not in updateConstraints because it doesn't play nice with UITableViewAutomaticDimension for some reason
    func changeConstraints() {
        let hasLongText = self.longLabel.text != nil && !self.longLabel.text.isEmpty
        if hasLongText != self.constraintsSetForLongLabel {
            self.removeConstraints(self.cellConstraints)
            self.cellConstraints.removeAll()
            self.addConstraints()
        }
    }
    
}
