//
//  SettingsViewController.swift
//  Travel Journal
//
//  Created by yusuf özden on 07/01/2024.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func logoutClicked(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "toHome", sender: nil)
        }catch{
            print("error")
        }
    }
    
    
}
