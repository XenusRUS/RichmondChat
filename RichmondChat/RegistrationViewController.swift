import UIKit
import Firebase

class RegistrationViewController: UIViewController {
    
    private let registrationSegue = "registrationSegue"

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirmButton(_ sender: Any) {
        if passwordTextField.text != confirmPasswordTextField.text {
            alertTheUser(title: "Пароли не совпадают", message: "Введенные пароли не совпадают между собой")
        }
        else {
            if emailTextField.text != "" && passwordTextField.text != "" {
                AuthProvider.Instance.signUp(withEmail: emailTextField.text!, password: passwordTextField.text!, loginHandler: { (message) in
                    
                    if message != nil {
                        self.alertTheUser(title: "Проблема с созданием нового пользователя", message: message!)
                    }
                    else {
                        self.emailTextField.text = ""
                        self.passwordTextField.text = ""
                        self.performSegue(withIdentifier: self.registrationSegue, sender: nil)
                    }
                    
                })
            }
            else {
                alertTheUser(title: "Требуется электронная почта и пароль", message: "Введите электронную почту и пароль")
            }
        }
    }
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
