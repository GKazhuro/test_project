//
//  SecondViewController.swift
//  test_project
//
//  Created by Георгий Кажуро on 18.09.16.
//  Copyright © 2016 Георгий Кажуро. All rights reserved.
//

import UIKit
import CoreData

class SecondViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var authStatus: UILabel!
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    let app = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext!
    
    var visitedSubs: [Int32] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginTextField.delegate = self
        passwordTextField.delegate = self
        
        context = app.managedObjectContext
        fetchData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        textField.resignFirstResponder()
        return true;
    }
    
    @IBAction func authButtonPressed(sender: AnyObject) {
        self.view.endEditing(true)
        if let login = loginTextField.text, login != "", let password = passwordTextField.text, password != "" {
            let authStringUrl = "http://httpbin.org/basic-auth/user/passwd"
            
            //Создание и добавления хэдера, содержащего инофрмацию об авторизации
            let loginString = NSString(format: "%@:%@", login, password)
            let loginData: Data = loginString.data(using: String.Encoding.utf8.rawValue)!
            let base64LoginString = loginData.base64EncodedString()
            let authUrl = URL(string: authStringUrl)
            
            //Запрос авторизации
            var request = URLRequest(url: authUrl!)
            request.httpMethod = "GET"
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            
            defaultSession.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, err: Error?) -> Void in
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        DispatchQueue.main.async {
                            self.authStatus.text = "Успех"
                            self.authStatus.textColor = UIColor(red: 95.0/255.0, green: 194.0/255.0, blue: 50.0/255.0, alpha: 1.0)
                            }
                    } else {
                        DispatchQueue.main.async {
                            self.authStatus.text = "Ошибка (user:passwd)"
                            self.authStatus.textColor = UIColor(red: 255.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
                        }
                    }
                }
            }).resume()
        }
    }
    
    @IBAction func yandexButtonPressed(sender: AnyObject) {
        
        deleteAllData(entity: "Category")
        
        let yandexStringUrl = "https://money.yandex.ru/api/categories-list"
        let yandexUrl = URL(string: yandexStringUrl)
        
        //Способ, описанный в статье, посвященной Concurrency, позволил избежать частых вылетов приложения из-за конфликтного обращения
        //основного и бэкграунд потоков к объекту NSManagedObjectContext
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = context
        
        defaultSession.dataTask(with: yandexUrl!, completionHandler:{ (data: Data?, response: URLResponse?, err: Error?) -> Void in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let dict = json as? [Dictionary<String, AnyObject>] {
                        //Добавление категорий
                        for cat in dict {
                            let entity = NSEntityDescription.entity(forEntityName: "Category", in: self.context)
                            let categoryObj = Category(entity: entity!, insertInto: self.context)
                            if let title = cat["title"] as? String {
                                categoryObj.title = title
                            }
                            //Если у категории есть подкатегории, то добавляем их
                            if let subs = cat["subs"] as? [Dictionary<String, AnyObject>] {
                                for sub in subs {
                                    let subObj = self.createSubObj(sub: sub)
                                    //Добавлем к подкатегориям, еще подкатегории, используя обход в глубину
                                    //В конкретном случае можно было его не использовать, однако в теории подкатегории, могли бы иметь еще несколько уровней,
                                    //содержащих объекты subs
                                    self.dfs_sub_add(sub: sub, subObj: subObj)
                                    
                                    categoryObj.addToSubs(subObj)
                                }
                            }
                            self.context.insert(categoryObj)
                        }
                        privateMOC.perform {
                            do {
                                try privateMOC.save()
                                self.context.performAndWait {
                                    do {
                                        try self.context.save()
                                    } catch {
                                        fatalError("Failure to save context: \(error)")
                                    }
                                }
                            } catch {
                                fatalError("Failure to save context: \(error)")
                            }
                        }
                    }
                } catch {
                    print("Couldn't serialize")
                }
                self.fetchData()
            }
        }).resume()
    }
    
    //Вывод данных в консоль
    func fetchData() {
        visitedSubs = []
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            for result in results {
                if let title = result.title {
                    print(title)
                }
                if let subs = result.subs {
                    for sub in subs.allObjects as! [Sub] {
                        if let title = sub.title {
                        print (sub.id)
                        print (title)
                        dfs_sub_print(subObj: sub)
                        }
                    }
                }
            }
        } catch {
            print ("Couldn't fetch")
        }
    }
    
    //Добавление подкатегорий, используя обход в глубину
    func dfs_sub_add(sub: Dictionary<String, AnyObject>, subObj: Sub) {
        visitedSubs.append(get_sub_id(sub: sub))
        if let uSubs = sub["subs"] as? [Dictionary<String, AnyObject>] {
            for uSub in uSubs {
                if (visitedSubs.contains(get_sub_id(sub: uSub))) == false  {
                    let newSubObj = createSubObj(sub: uSub)
                    subObj.addToSubs(newSubObj)
                    dfs_sub_add(sub: uSub, subObj: newSubObj)
                }
            }
        }
    }
    
    //Вывод подкатегорий, используя обход в глубину
    func dfs_sub_print(subObj: Sub) {
        visitedSubs.append(subObj.id)
        if let uSubs = subObj.subs {
            for uSub in uSubs.allObjects as! [Sub] {
                if (visitedSubs.contains(uSub.id)) == false  {
                    print (uSub.id)
                    print (uSub.title!)
                    dfs_sub_print(subObj: uSub)
                }
            }
        }
    }
    
    //Получение id подкатегории
    func get_sub_id(sub: Dictionary<String, AnyObject>) -> Int32 {
        if let id = sub["id"] as? Int {
            return Int32(id)
        }
        else {
            return -1
        }
    }
    
    //Создание объекта подкатегории
    func createSubObj(sub: Dictionary<String, AnyObject>) -> Sub {
        let entity = NSEntityDescription.entity(forEntityName: "Sub", in: context)
        let subObj = Sub(entity: entity!, insertInto: context)
        if let id = sub["id"] as? Int {
            subObj.id = Int32(id)
        }
        if let title = sub["title"] as? String {
            subObj.title = title
        }
        return subObj
    }
    
    //Очистка всех данных
    func deleteAllData(entity: String)
    {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = context
        
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        do
        {
            let results = try context.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as NSManagedObject
                let objectID = managedObjectData.objectID
                let managedObjectFromID = privateMOC.object(with: objectID)
                privateMOC.delete(managedObjectFromID)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }


}

