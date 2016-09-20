//
//  ContactCell.swift
//  test_project
//
//  Created by Георгий Кажуро on 18.09.16.
//  Copyright © 2016 Георгий Кажуро. All rights reserved.
//

import UIKit
import Contacts

class ContactCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var bday: UILabel!
    @IBOutlet weak var contactImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        //Что-то делаю не так, либо проблемы с Xcode 8
        //contactImage.layer.cornerRadius = contactImage.frame.size.width / 2
        
        contactImage.layer.cornerRadius = 30
        contactImage.clipsToBounds = true
    }
    
    func configureCell(contact: CNContact) {
        contactImage.contentMode = UIViewContentMode.scaleAspectFill
        
        name.text = "\(contact.givenName) \(contact.familyName)"
        if let birthday = contact.birthday {
            bday.text = getDateString(components: birthday)
        }
        if let imageData = contact.imageData {
            contactImage.image = UIImage(data: imageData)
        } else {
            contactImage.image = UIImage(named: "defaultContact")
        }
    }
    
    func getDateString(components: DateComponents) -> String {
        let date = NSCalendar.current.date(from: components)
        let formatter = DateFormatter()
        
        if components.year != nil {
            formatter.dateFormat = "d MMMM, yyyy"
        } else {
            formatter.dateFormat = "d MMMM"
        }
        
        if let date = date {
            let dateString = formatter.string(from: date)
            return dateString
        } else {
            return ""
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
