import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseAuth

class ChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchData {

    @IBOutlet weak var tableView: UITableView!
    
    private var contacts = [Contact]()
    private let chatSegue = "chatSegue"
    
    private var messages = [JSQMessage]()
    
    let senderID = AuthProvider.Instance.userID()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        DBProvider.Instance.delegate = self
        DBProvider.Instance.getContacts()
    }
    
    func dataReceived(contacts: [Contact]) {
        self.contacts = contacts
        
        for contact in contacts {
            if contact.id == AuthProvider.Instance.userID() {
                AuthProvider.Instance.userName = contact.name
            }
        }
        
        tableView.reloadData()
    }
    
    @IBAction func logout(_ sender: Any) {
        if AuthProvider.Instance.logOut() {
            dismiss(animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)

        cell.textLabel?.text = contacts[indexPath.row].name
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let destinationNavigationController = segue.destination as! UINavigationController
//        let targetController = destinationNavigationController.topViewController
        if let destination = segue.destination as? ChatViewController {
            let selectedRow = tableView.indexPathForSelectedRow!.row
            destination.contactID = contacts[selectedRow].id
        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: chatSegue, sender: nil)
//    }
    
}
