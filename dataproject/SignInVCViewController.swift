//
//  SignInVCViewController.swift
//  Travel Journal
//
//  Created by yusuf özden on 07/01/2024.
//

import UIKit
import FirebaseAuth
import Firebase


class SignInVCViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
       
    }
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    

    @IBAction func signUpClicked(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != "" {
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { authdata, error in
                if error != nil {
                    self.makeAlert(title1: "Error", message1: error?.localizedDescription ?? "Error")
                }else{
                    self.performSegue(withIdentifier: "toNC", sender: nil)
                }
            }
        }
        else {
           makeAlert(title1: "Error", message1: "Email and password cannot be empty!")
           
        }
    }
    
    @IBAction func signInClicked(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != ""{
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { authdata , error in
                if error != nil{
                    self.makeAlert(title1: "Error", message1: error?.localizedDescription ?? "Error")
                }else{
                    self.performSegue(withIdentifier: "toNC", sender: nil)
                }
            }
        }else{
            makeAlert(title1: "Error", message1: "Email and password cannot be empty!")
        }
    }
    func makeAlert(title1 : String, message1 : String){
        let alert = UIAlertController(title: title1, message: message1, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        alert.addAction(okButton)
        self.present(alert, animated: true)
    }
    
}
