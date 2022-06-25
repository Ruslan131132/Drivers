import UIKit
import CoreData

struct KeychainConfiguration {
  static let serviceName = "TouchMeIn"
  static let accessGroup: String? = nil
}

class LoginViewController: UIViewController {

  // MARK: - Properties
  var passwordItems: [KeychainPasswordItem] = []
  let createLoginButtonTag = 0
  let loginButtonTag = 1
  let touchMe = BiometricIDAuth()
  var managedObjectContext: NSManagedObjectContext?

  // MARK: - IBOutlets
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var touchIDButton: UIButton!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let hasLogin = UserDefaults.standard.bool(forKey: "hasLoginKey")
    
    if hasLogin {
      loginButton.setTitle("Войти", for: .normal)
      loginButton.tag = loginButtonTag
//      createInfoLabel.isHidden = true
    } else {
      loginButton.setTitle("Создать", for: .normal)
      loginButton.tag = createLoginButtonTag
//      createInfoLabel.isHidden = false
    }
    
    if let storedUsername = UserDefaults.standard.value(forKey: "username") as? String {
      usernameTextField.text = storedUsername
    }
    
    touchIDButton.isHidden = !touchMe.canEvaluatePolicy()

    switch touchMe.biometricType() {
    case .faceID:
      touchIDButton.setImage(UIImage(named: "FaceIcon"),  for: .normal)
    default:
      touchIDButton.setImage(UIImage(named: "Touch-icon-lg"),  for: .normal)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let touchBool = touchMe.canEvaluatePolicy()
    if touchBool {
      self.touchIDLoginAction()
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: - Action for checking username/password
  @IBAction func loginAction(sender: UIButton) {
    // Check that text has been entered into both the username and password fields.
    guard let newAccountName = usernameTextField.text,
      let newPassword = passwordTextField.text,
      !newAccountName.isEmpty,
      !newPassword.isEmpty else {
        showLoginFailedAlert()
        return
    }
    
    usernameTextField.resignFirstResponder()
    passwordTextField.resignFirstResponder()
    
    if sender.tag == createLoginButtonTag {
      let hasLoginKey = UserDefaults.standard.bool(forKey: "hasLoginKey")
      if !hasLoginKey && usernameTextField.hasText {
        UserDefaults.standard.setValue(usernameTextField.text, forKey: "username")
      }
      
      do {
        
        // This is a new account, create a new keychain item with the account name.
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                account: newAccountName,
                                                accessGroup: KeychainConfiguration.accessGroup)
        
        // Save the password for the new item.
        try passwordItem.savePassword(newPassword)
      } catch {
        fatalError("Ошибка обновления keychain - \(error)")
      }
      
      UserDefaults.standard.set(true, forKey: "hasLoginKey")
      loginButton.tag = loginButtonTag
      
      performSegue(withIdentifier: "dismissLogin", sender: self)
      
    } else if sender.tag == loginButtonTag {
      if checkLogin(username: newAccountName, password: newPassword) {
        performSegue(withIdentifier: "dismissLogin", sender: self)
      } else {
        showLoginFailedAlert()
      }
    }
  }
  
  @IBAction func touchIDLoginAction() {
    touchMe.authenticateUser() { [weak self] message in
      if let message = message {
        if (message == "You pressed cancel." || message == "You pressed password."){
          return;
        }
            
        // if the completion is not nil show an alert
//        let alertView = UIAlertController(title: "Error",
//                                          message: message,
//                                          preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "Darn!", style: .default)
//        alertView.addAction(okAction)
//        self?.present(alertView, animated: true)
        
      } else {
        self?.performSegue(withIdentifier: "dismissLogin", sender: self)
      }
    }
  }

  func checkLogin(username: String, password: String) -> Bool {
    guard username == UserDefaults.standard.value(forKey: "username") as? String else {
      return false
    }
    
    do {
      let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                              account: username,
                                              accessGroup: KeychainConfiguration.accessGroup)
      let keychainPassword = try passwordItem.readPassword()
      return password == keychainPassword
    }
    catch {
      fatalError("Error reading password from keychain - \(error)")
    }
    return false
  }
  
  private func showLoginFailedAlert() {
    let alertView = UIAlertController(title: "Ошибка авторизации",
                                      message: "Неверный логин или пароль",
                                      preferredStyle:. alert)
    let okAction = UIAlertAction(title: "Попробовать еще раз", style: .default)
    alertView.addAction(okAction)
    present(alertView, animated: true)
  }
}
