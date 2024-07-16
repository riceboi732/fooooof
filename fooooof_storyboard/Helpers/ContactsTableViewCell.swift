//
//  ContactsTableViewCell.swift
//  fooooof_storyboard
//
//  Created by Jessica Chen on 1/3/23.
//

import UIKit

protocol ContactsTableViewCellDelegate: AnyObject {
    func didTapButton(title: String, index: Int)
}

class ContactsTableViewCell: UITableViewCell {
    
    weak var delegate: ContactsTableViewCellDelegate?

    static let identifier = "ContactsTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "ContactsTableViewCell", bundle: nil)
    }
    
    @IBOutlet var button: UIButton!
    private var title: String = ""
    private var index: Int = 0
    
    @IBAction func didTapButton() {
        delegate?.didTapButton(title: title, index: index)
    }
    
    func configure(title: String, index: Int) {
        self.title = title
        self.index = index
        button.setTitle(title, for: .normal)
        //TODO: change font (doesn't show for some reason)
    }
    
    func setButton(title: String) {
        button.setTitle(title, for: .normal)
    }
    
    func getButtonText() -> String{
        return button.titleLabel?.text ?? ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.setTitleColor(.white, for: .normal)
    }
}
