import UIKit
import Firebase

class ViewController: UIViewController {
    
    private let loginSegue = "loginSegue"

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        passwordField.isSecureTextEntry = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if AuthProvider.Instance.isLoggedIn() {
            performSegue(withIdentifier: self.loginSegue, sender: nil)
        }
    }


    @IBAction func loginButton(_ sender: Any) {
        if emailField.text != "" && passwordField.text != "" {
            AuthProvider.Instance.login(withEmail: emailField.text!, password: passwordField.text!, loginHandler: { (message) in
                
                if message != nil {
                   self.alertTheUser(title: "Проблема со входом", message: message!)
                }
                else {
                    self.emailField.text = ""
                    self.passwordField.text = ""
                    self.performSegue(withIdentifier: self.loginSegue, sender: nil)
                }
                
            })
        }
        else {
            alertTheUser(title: "Требуется электронная почта и пароль", message: "Введите электронную почту и пароль")
        }
    }
    
    @IBAction func registrationButton(_ sender: Any) {
        
    }
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
}
