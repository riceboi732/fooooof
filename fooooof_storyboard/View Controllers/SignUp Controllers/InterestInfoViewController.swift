//import UIKit
//import TTGTagCollectionView
//import TagListView
//
//class InterestInfoViewController: UIViewController, TTGTextTagCollectionViewDelegate,TagListViewDelegate {
//
//    @IBOutlet weak var backButton: UIButton!
//    @IBOutlet weak var skipButton: UIButton!
//    @IBOutlet weak var nextButton: UIButton!
////    @IBOutlet weak var errorLabel: UILabel!
//    @IBOutlet weak var TagCollectionView: UIView!
//
//    let collectionView = TTGTextTagCollectionView()
//
//    private var selections = [String]()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        collectionView.alignment = .center
//        collectionView.delegate = self
//
//        view.addSubview(collectionView)
//
//        let config = TTGTextTagConfig()
//        config.backgroundColor = .systemBlue
//        config.textColor = .white
//        config.borderColor = .systemOrange
//        config.borderWidth = 1
//
//        collectionView.addTags(["Reading","Anime","Manga","Working Out", "Music", "Sports","Travel","Poker","Beer","Hiking","Golf","Squash", "Skiing","Snowboarding","Creative Writing", "Dating"], with: config)
////        setUpElements()
//    }
//
////    func setUpElements() {
////        errorLabel.isHidden = true
////    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        collectionView.frame = CGRect(x: 0, y: 200, width: view.frame.size.width, height: 300)
//    }
//
//    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool, tagConfig config: TTGTextTagConfig!) {
//        selections.append(tagText)
//    }
//
////    @IBAction func nextButtonTapped(_ sender: Any) {
//////        if selections.isEmpty{
//////            errorLabel.isHidden = false
//////            errorLabel.text = "Please enter information in all fields"
//////        }
//////        else{
//////            errorLabel.isHidden = true
////            UserDefaults.standard.set(selections, forKey: "interests")
////            let controller = storyboard?.instantiateViewController(identifier: "finalProfileCreation") as! FinalProfileCreationViewController
////            controller.modalTransitionStyle = .crossDissolve
////            controller.modalPresentationStyle = .fullScreen
////            present(controller, animated: true, completion: nil)
//////        }
////    }
//
//    @IBAction func backButtonTapped(_ sender: Any) {
//        let controller = storyboard?.instantiateViewController(identifier: "photoCollageViewController") as! PhotoCollageViewController
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
//
//    @IBAction func skipButtonPressed(_ sender: Any) {
//        let controller = storyboard?.instantiateViewController(identifier: "professionalInfoViewController") as! ProfessionalInfoViewController
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
//
//}
//
