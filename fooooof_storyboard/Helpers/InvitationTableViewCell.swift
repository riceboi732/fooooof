import UIKit

protocol InvitationTableViewCellDelegate: AnyObject {
    func didTapButton(title: String, index: Int)
    func didTapDeclineButton(index: Int)
}

class InvitationTableViewCell: UITableViewCell {
    
    weak var delegate: InvitationTableViewCellDelegate?

    static let identifier = "InvitationTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "InvitationTableViewCell", bundle: nil)
    }
    
    @IBOutlet var button: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    private var title: String = ""
    private var index: Int = 0
    @IBOutlet weak var viewInside: UIView!
    @IBOutlet weak var userNameText: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBAction func didTapButton() {
        delegate?.didTapButton(title: title, index: index)
    }
    @IBAction func didTapDeclineButton() {
        delegate?.didTapDeclineButton(index: index)
    }
    
    func configure(title: String, index: Int) {
        self.title = title
        self.index = index
        button.setTitle(title, for: .normal)
        button.isEnabled = true
        declineButton.isEnabled = true
        viewInside.layer.cornerRadius = 25
        viewInside.layer.masksToBounds = true
        backgroundColor = UIColor.white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
