//
//  FirstViewController.swift
//  test_project
//
//  Created by Георгий Кажуро on 18.09.16.
//  Copyright © 2016 Георгий Кажуро. All rights reserved.
//

import UIKit
import Contacts

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var contactStore = CNContactStore()
    var contacts = [CNContact]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        contacts = []
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        //Проверка доступа приложения к Контактам пользователя
        switch authStatus {
        case .authorized:
            fetchContacts()
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: .contacts, completionHandler: { (access, err) -> Void in
                if access {
                    self.fetchContacts()
                }
            })
        default:
            print("Not handled")
        }
    }
    
    //Получение контактов
    func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey, CNContactImageDataKey]
        do {
            try contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])){ (contact, pointer) -> Void in
                //Выбираем только с указанным Днем Рождения
                if contact.birthday != nil {
                    self.contacts.append(contact)
                    self.tableView.reloadData()
                }
            }
        }
        catch let error as NSError {
            print(error.description)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell") as? ContactCell {
            let contact = contacts[indexPath.row]
            cell.configureCell(contact: contact)
            return cell
        } else {
            return ContactCell()
        }
    }


}

