//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()

    var messages : [Message] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Constants.appName
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        
        loadMessages()

    }
    
    func loadMessages (){
        
        db.collection(Constants.FStore.collectionName)
            .order(by: Constants.FStore.dateField)
            .addSnapshotListener { querySnapshot, error in
            
            self.messages = []
            
            if let error = error {
                print(error.localizedDescription)
            }else{
                if let snapshotDocuments = querySnapshot?.documents  {
                    for snapshotDocument in snapshotDocuments {
                        let snapshotData = snapshotDocument.data()
                        let snapshotSenderId =  Constants.FStore.senderField
                        let snapshotBodyId = Constants.FStore.bodyField
                        if let snapshotSender = snapshotData[snapshotSenderId] as? String , let snapshotMessageBody = snapshotData[snapshotBodyId] as? String {
                            let newMessage = Message(sender: snapshotSender, body: snapshotMessageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                
                                self.tableView.reloadData()
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "There is no text", message: "Add some text in a message", preferredStyle: .alert)
        let agreeButton = UIAlertAction(title: "OK", style: .default , handler: nil)
        alert.addAction(agreeButton)
        if let messageBody = messageTextfield.text , let messageSender = Auth.auth().currentUser?.email {
            if messageBody.isEmpty {
                self.present(alert, animated: true)
            }else {
                db.collection(Constants.FStore.collectionName).addDocument(data: [
                    Constants.FStore.senderField : messageSender ,
                    Constants.FStore.bodyField : messageBody ,
                    Constants.FStore.dateField : Date().timeIntervalSince1970]) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }else{
                            DispatchQueue.main.async {
                                self.messageTextfield.text = ""
                            }
                        }
                }
            }
            
        }
        
        
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
           try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
      
    }
    
}

//MARK: - UITableViewDataSource

extension ChatViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
            as! MessageCell
        cell.label.text  = message.body
        
        //Message from current user
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: Constants.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: Constants.BrandColors.purple)
        }//Message from another sender
        else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: Constants.BrandColors.purple)
            cell.label.textColor     = UIColor(named: Constants.BrandColors.lightPurple)
        }

        return cell
    }
}

//MARK: - UITableViewDelegate

extension ChatViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
    }
}
