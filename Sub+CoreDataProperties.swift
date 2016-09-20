//
//  Sub+CoreDataProperties.swift
//  test_project
//
//  Created by Георгий Кажуро on 19.09.16.
//  Copyright © 2016 Георгий Кажуро. All rights reserved.
//

import Foundation
import CoreData

extension Sub {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sub> {
        return NSFetchRequest<Sub>(entityName: "Sub");
    }

    @NSManaged public var id: Int32
    @NSManaged public var title: String?
    @NSManaged public var category: Category?
    @NSManaged public var subs: NSSet?

}

// MARK: Generated accessors for subs
extension Sub {

    @objc(addSubsObject:)
    @NSManaged public func addToSubs(_ value: Sub)

    @objc(removeSubsObject:)
    @NSManaged public func removeFromSubs(_ value: Sub)

    @objc(addSubs:)
    @NSManaged public func addToSubs(_ values: NSSet)

    @objc(removeSubs:)
    @NSManaged public func removeFromSubs(_ values: NSSet)

}
