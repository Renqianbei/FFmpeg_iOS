//
//  ViewController.swift
//  HelloFF
//
//  Created by 任前辈 on 2019/11/12.
//  Copyright © 2019 任前辈. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red
        HelloFMP.startApi(self.view, inPath: Bundle.main.path(forResource: "myvideo", ofType: "mov")!)
        // Do any additional setup after loading the view.
    }


}

