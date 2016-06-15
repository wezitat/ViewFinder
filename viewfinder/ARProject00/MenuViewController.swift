//
//  MenuViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/12/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var sceneButton: UIButton!
    @IBOutlet weak var bothButton: UIButton!
    
    override func viewDidLoad() {
        
        sblog.info("menuViewController didLoad")
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    

    /*
     MARK: - Navigation

     In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
         Get the new view controller using segue.destinationViewController.
         Pass the selected object to the new view controller.
    }
    */

}
