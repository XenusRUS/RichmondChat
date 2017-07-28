import Foundation
import FirebaseDatabase
import FirebaseStorage

protocol MessagesReceivedDelegate: class {
    func messageReceived(senderID: String, senderName: String, text: String, toID: String)
    func mediaReceived(senderID: String, senderName: String, url: String)
}

class MessagesHandler {
    
    var toIDArr: NSMutableArray!
    
    private static let _instance = MessagesHandler()
    private init() {}
    
    weak var delegate: MessagesReceivedDelegate?
    
    static var Instance: MessagesHandler {
        return _instance
    }
    
    func sendMessages(senderID: String, senderName: String, text: String, toID: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.TEXT: text, Constants.TO_ID: toID]
        
        DBProvider.Instance.messagesRef.childByAutoId().setValue(data)
    }
    
    func sendMediaMessage(senderID: String, senderName: String, url: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.URL: url]
        
        DBProvider.Instance.mediaMessagesRef.childByAutoId().setValue(data)
    }
    
    func sendMedia(image: Data?, video: URL?, senderID: String, senderName: String) {
        if image != nil {
            DBProvider.Instance.imageStorageRef.child(senderID + "\(NSUUID().uuidString).jpg").putData(image!, metadata: nil) { (metadata: StorageMetadata?, err: Error?) in
                if err != nil {
                }
                else {
                    self.sendMediaMessage(senderID: senderID, senderName: senderName, url: String(describing: metadata!.downloadURL()!))
                }
            }
        }
        else {
            DBProvider.Instance.videoStorageRef.child(senderID + "\(NSUUID().uuidString)").putFile(from: video!, metadata: nil) { (metadata: StorageMetadata?, err: Error?) in
                if err != nil {
                    
                }
                else {
                    self.sendMediaMessage(senderID: senderID, senderName: senderName, url: String(describing: metadata!.downloadURL()!))
                }
            }
        }
    }
    
    func observeMessages() {
        DBProvider.Instance.messagesRef.observe(DataEventType.childAdded)  { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let senderID = data[Constants.SENDER_ID] as? String {
                    if let senderName = data[Constants.SENDER_NAME] as? String {
                        if let text = data[Constants.TEXT] as? String {
                            if let toID = data[Constants.TO_ID] as? String {
                                if data[Constants.SENDER_ID] as! String == AuthProvider.Instance.userID() || data[Constants.TO_ID] as! String == AuthProvider.Instance.userID() {
                                self.delegate?.messageReceived(senderID: senderID, senderName: senderName, text: text, toID: toID)
                                }
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    func observeMediaMessages() {
        DBProvider.Instance.mediaMessagesRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let id = data[Constants.SENDER_ID] as? String {
                    if let name = data[Constants.SENDER_NAME] as? String {
                        if let fileURL = data[Constants.URL] as? String {
                            self.delegate?.mediaReceived(senderID: id, senderName: name, url: fileURL)
                        }
                    }
                }
            }
        }
    }
    
}
