//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
        
        
    }
    
    func loadMessages() {
        
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapshot, error ) in
                
                self.messages = []
                
                if let error = error {
                    print("There was an issue retrieving data from Firestore.\(error)")
                    return
                }
                guard let snapshotDocuments = querySnapshot?.documents else { return }
                for doc in snapshotDocuments {
                    let data = doc.data()
                    guard let messagesSender = data[K.FStore.senderField] as? String,
                          let messageBody = data[K.FStore.bodyField] as? String else { return }
                    let newMessage = Message(sender: messagesSender, body: messageBody)
                    self.messages.append(newMessage)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    }
                }
            }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        guard let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email else { return }
        db.collection(K.FStore.collectionName).addDocument(data: [
            K.FStore.senderField: messageSender,
            K.FStore.bodyField: messageBody,
            K.FStore.dateField: Date().timeIntervalSince1970
        ]) { (error) in
            if let error = error {
                print("There was an issue saving data to firestore, \(error)")
            } else {
                print("Successfully saved data.")
                
                DispatchQueue.main.async {
                    self.messageTextfield.text = ""
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        //元のdo文が適切か分からない、とりあえずguard文に修正した
        guard let _ = try? Auth.auth().signOut() else {
            print("Error signing out")
            return
        }
        navigationController?.popToRootViewController(animated: true)
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as? MessageCell else { return UITableViewCell() }
        cell.label.text = message.body
        
        let isCurrentUser = message.sender == Auth.auth().currentUser?.email
        cell.leftImageView.isHidden = isCurrentUser
        cell.rightImageView.isHidden = !isCurrentUser
        cell.messageBubble.backgroundColor = isCurrentUser ? UIColor(named: K.BrandColors.lightPurple) : UIColor(named: K.BrandColors.purple)
        cell.label.textColor = isCurrentUser ? UIColor(named: K.BrandColors.purple) : UIColor(named: K.BrandColors.lightPurple)
        
        return cell
    }
}

