//
//   ViewController.swift
//   IATAblumareks
// 

import UIKit
import SwiftSpinner
import ConversationV1
import JSQMessagesViewController
import BMSCore




class ViewController: JSQMessagesViewController {
    
    // Configure chat settings for JSQMessages
    let incomingChatBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    let outgoingChatBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    fileprivate let kCollectionViewCellHeight: CGFloat = 12.5
    
    // Configure Watson Conversation items
    var conversationMessages = [JSQMessage]()
    var conversation : Conversation!
    var context: Context?
    var workspaceID: String!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupTextBubbles()
        // Remove attachment icon from toolbar
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func reloadMessagesView() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SwiftSpinner.show("Connecting to Watson", animated: true)
        // Create a configuration path for the BMSCredentials.plist file to read in Watson credentials
        let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist")
        let configuration = NSDictionary(contentsOfFile: configurationPath!)
        // Set the Watson credentials for Conversation service from the BMSCredentials.plist
        let conversationPassword = configuration?["conversationPassword"] as! String //these details come from the wizard and are stored in the BMSCredentials.plist - please use your own credetials!
        let conversationUsername = configuration?["conversationUsername"] as! String //these details come from the wizard and are stored in the BMSCredentials.plist - please use your own credetials!
        let conversationWorkspaceID = "ed4a90de-4705-4dd1-b79d-c5ad1d129430" //add the workspace ID from Dialog at the Conversation Service.
        
        //Workspace ID for 
        //my travel: ed4a90de-4705-4dd1-b79d-c5ad1d129430
        // Q&A on Mobile Services: 11c12e2b-05d2-4b72-b770-9b8aae0fbf6b
        // car dash: 38075364-953d-4ab7-aa75-65dedfd43540
        
        self.workspaceID = conversationWorkspaceID
        // Create date format for Conversation service version
        let version = "2016-12-15"
        // Initialize conversation object
        conversation = Conversation(username: conversationUsername, password: conversationPassword, version: version)
        // Initial conversation message from Watson
        conversation.message(withWorkspace: self.workspaceID, failure: failConversationWithError){
            response in
            for watsonMessage in response.output.text{
                // Create message object with Watson response
                let message = JSQMessage(senderId: "Watson", displayName: "Watson", text: watsonMessage)
                // Add message to conversation message array
                self.conversationMessages.append(message!)
                // Set current context
                self.context = response.context
                DispatchQueue.main.async {
                    self.finishSendingMessage()
                    SwiftSpinner.hide()
                }
            }
        }
    }
    
    func didBecomeActive(_ notification: Notification) {
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Function handling errors with Tone Analyzer
    func failConversationWithError(_ error: Error) {
        // Print the error to the console
        print(error)
        SwiftSpinner.hide()
        // Present an alert to the user describing what the problem may be
        DispatchQueue.main.async {
            self.showAlert("Conversation Failed", alertMessage: "The Conversation service failed to reply. This could be due to invalid creditials, internet connection or other errors. Please verify your credentials in the WatsonCredentials.plist and rebuild the application. See the README for further assistance.")
        }
    }
    
    // Function to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ alertTitle: String, alertMessage: String){
        // If an alert is not currently being displayed
        if(self.presentedViewController == nil){
            // Set alert properties
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            // Add an action to the alert
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            // Show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Setup text bubbles for conversation
    func setupTextBubbles() {
        // Create sender Id and display name for user
        self.senderId = "TestUser"
        self.senderDisplayName = "TestUser"
        // Set avatars for user and Watson
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 28, height:32 )
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 37, height:37 )
        automaticallyScrollsToMostRecentMessage = true
        
    }
    // Set how many items are in the collection view
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.conversationMessages.count
    }
    
    // Set message data for each item in the collection view
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.conversationMessages[indexPath.row]
        
    }
    
    // Set whih bubble image is used for each message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return conversationMessages[indexPath.item].senderId == self.senderId ? outgoingChatBubble : incomingChatBubble
        
    }
    
    // Set which avatar image is used for each chat bubble
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message = conversationMessages[(indexPath as NSIndexPath).item]
        var avatar: JSQMessagesAvatarImage
        if (message.senderId == self.senderId){
            avatar  = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"avatar_small"), diameter: 37)
        }
        else{
            avatar  = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named:"watson_avatar"), diameter: 32)
        }
        return avatar
    }
    
    // Create and display timestamp for every third message in the collection view
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        if ((indexPath as NSIndexPath).item % 3 == 0) {
            let message = conversationMessages[(indexPath as NSIndexPath).item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }
    
    // Set the height for the label that holds the timestamp
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return kCollectionViewCellHeight
    }
    
    // Create the cell for each item in collection view
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
            as! JSQMessagesCollectionViewCell
        let message = self.conversationMessages[(indexPath as NSIndexPath).item]
        // Set the UI color of each cell based on who the sender is
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.black
        } else {
            cell.textView!.textColor = UIColor.white
        }
        return cell
    }
    
    // Handle actions when user presses send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // Create message based on user text
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        // Add message to conversation messages array of JSQMessages
        self.conversationMessages.append(message!)
        DispatchQueue.main.async {
            self.finishSendingMessage()
        }
        
        // Get response from Watson based on user text
        let messageRequest = MessageRequest(text: text, context: self.context)
        conversation.message(withWorkspace: self.workspaceID, request: messageRequest, failure: failConversationWithError) { response in
            // Set current context
            self.context = response.context
            // Handle Watson response
            for watsonMessage in response.output.text{
                if(!watsonMessage.isEmpty){
                    // Create message based on Watson response
                    let message = JSQMessage(senderId: "Watson", displayName: "Watson", text: watsonMessage)
                    // Add message to conversation message array
                    self.conversationMessages.append(message!)
                    DispatchQueue.main.async {
                        self.finishSendingMessage()
                    }
                }
            }
        }
    }
}
