import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import SDWebImage
import Firebase
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class ChatViewController: JSQMessagesViewController, MessagesReceivedDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var contactID: String!
    
    private var messages = [JSQMessage]()
    private var toIdArr = [String]()
    
    let picker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        MessagesHandler.Instance.delegate = self
        
        self.senderId = AuthProvider.Instance.userID()
        self.senderDisplayName = AuthProvider.Instance.userName
        
        MessagesHandler.Instance.observeMessages()
        MessagesHandler.Instance.observeMediaMessages()
        
        self.inputToolbar.contentView.leftBarButtonItem = nil // hide accessory button
    }
    
    // collection view func
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactrory = JSQMessagesBubbleImageFactory()
        let message = messages[indexPath.item]
        let toID = toIdArr[indexPath.item]
        
        if message.senderId == self.senderId  {
            if self.contactID == toID {
                return bubbleFactrory?.outgoingMessagesBubbleImage(with: UIColor.blue)
            }
        }
        if message.senderId == self.contactID  {
            if self.senderId == toID {
                return bubbleFactrory?.incomingMessagesBubbleImage(with: UIColor.green)
            }
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        collectionView?.collectionViewLayout.incomingAvatarViewSize = .zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "no-avatar.gif"), diameter: 30)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let msg = messages[indexPath.item]
        
        if msg.isMediaMessage {
            if let mediaItem = msg.media as? JSQVideoMediaItem {
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerController = AVPlayerViewController()
                playerController.player = player
                self.present(playerController, animated: true, completion: nil)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    // end collection view func
    
    // sending buttons func
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        MessagesHandler.Instance.sendMessages(senderID: senderId, senderName: senderDisplayName, text: text, toID: contactID)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let alert = UIAlertController(title: "Медиа", message: "Выберите фото или видео", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        let photos = UIAlertAction(title: "Фото", style: .default, handler: { (alert: UIAlertAction) in
            self.chooseMedia(type: kUTTypeImage)
        })
        
        let videos = UIAlertAction(title: "Видео", style: .default, handler: { (alert: UIAlertAction) in
            self.chooseMedia(type: kUTTypeMovie)
        })
        
        alert.addAction(photos)
        alert.addAction(videos)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    // end sending buttons func
    
    // picker view func
    
    private func chooseMedia(type: CFString) {
        picker.mediaTypes = [type as String]
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pic = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let data = UIImageJPEGRepresentation(pic, 0.01)
            MessagesHandler.Instance.sendMedia(image: data, video: nil, senderID: senderId, senderName: senderDisplayName)
        }
        else if let vidUrl = info[UIImagePickerControllerMediaURL] as? URL {
            MessagesHandler.Instance.sendMedia(image: nil, video: vidUrl, senderID: senderId, senderName: senderDisplayName)
        }
        
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
    
    // end picker view func
    
    // delegation func
    
    func messageReceived(senderID: String, senderName: String, text: String, toID: String) {
        
        if senderID == self.senderId && toID == self.contactID || senderID == self.contactID && toID == self.senderId {
            messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
            toIdArr.append(toID)
        }
        collectionView.reloadData()
    }
    
    func mediaReceived(senderID: String, senderName: String, url: String) {
        if let mediaURL =  URL(string: url) {
            do {
                let data = try Data(contentsOf: mediaURL)
                if let _ = UIImage(data: data) {
                    let _ = SDWebImageDownloader.shared().downloadImage(with: mediaURL, options: [], progress: nil, completed: { (image, data, error, finished) in
                        DispatchQueue.main.async {
                            let photo = JSQPhotoMediaItem(image: image)
                            if senderID == self.senderId {
                                photo?.appliesMediaViewMaskAsOutgoing = true
                            }
                            else {
                                photo?.appliesMediaViewMaskAsOutgoing = false
                            }
                            self.messages.append(JSQMessage(senderId: senderID, displayName: senderName, media: photo))
//                            self.toIdArr.append(toID)
                            self.collectionView.reloadData()
                        }
                    })
                }
                else {
                    let video = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                    if senderID == self.senderId {
                        video?.appliesMediaViewMaskAsOutgoing = true
                    }
                    else {
                        video?.appliesMediaViewMaskAsOutgoing = false
                    }
                    messages.append(JSQMessage(senderId: senderID, displayName: senderName, media: video))
//                    toIdArr.append(toID)
                    self.collectionView.reloadData()
                }
            }
            catch {
                
            }
        }
    }
    
    // end delegation func
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
