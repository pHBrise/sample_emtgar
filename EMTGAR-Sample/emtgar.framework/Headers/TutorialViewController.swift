//
//  TutorialViewController.swift
//  emtgar-swift
//
//  Created by Mac mini ssd500 on 13/5/20.
//  Copyright © 2020 Nadia Thailand. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    
    var tutorialDelegate:TutorialDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func touchUpInsideOkBtn(_ sender: Any) {
        tutorialDelegate?.closeTutorial()
        self.dismiss(animated: false, completion: nil)
    }


}
