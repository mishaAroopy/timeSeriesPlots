//
//  JournalEntry.swift
//  TimeSeriesPlots
//
//  Created by AINSLIE YUEN on 4/20/17.
//  Copyright © 2017 Aroopy. All rights reserved.
//

import UIKit

class JournalEntry: NSObject, NSCoding {
    
    // MARK: Properties
    var text: String
    var photo: UIImage?
    var date: Date
    
    // MARK: Archiving Paths
    //You mark these constants with the static keyword, which means they apply to the class instead of an instance of the class. Outside of the Meal class, you’ll access the path using the syntax Meal.ArchiveURL.path!.
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("journals")
    
    // MARK: Types
    struct PropertyKey {
        static let textKey = "text"
        static let photoKey = "photo"
        static let dateKey = "date"
    }
    
    // MARK: Initialization
    init?( text: String, photo: UIImage?, date: Date){
        // Initalize stored properties
        self.text = text
        self.photo = photo
        self.date = date
        super.init()
        // Initialization should fail if there is no name and no photo
        if ((text.isEmpty) && (photo == nil)) {
            return nil
        }
    }
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(text, forKey: PropertyKey.textKey)
        aCoder.encode(photo, forKey: PropertyKey.photoKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
    }
    required convenience init?( coder aDecoder: NSCoder){
        let text = aDecoder.decodeObject(forKey: PropertyKey.textKey) as! String
        // Because photo is an optional property of Meal, use conditional cast.
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photoKey) as? UIImage
        let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as! Date
        // Must call designated initializer.
        self.init(text: text, photo: photo, date: date)
    }
}

// MARK: NSCoding
func saveJournalEntries( _ myJournals: [JournalEntry]){
    var myJournals = myJournals
    myJournals.sort(by: { (arg1, arg2) -> Bool in
        return ( arg1.date.compare( arg2.date as Date ) == .orderedDescending )
    })
    let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(myJournals, toFile: JournalEntry.ArchiveURL.path)
    if !isSuccessfulSave {
        print("Failed to save journal entries...")
    }
}
func loadJournalEntries() -> [JournalEntry]?{
    var foundJournals = NSKeyedUnarchiver.unarchiveObject(withFile: JournalEntry.ArchiveURL.path) as? [JournalEntry]
    if let _ = foundJournals {
        foundJournals!.sort(by: { (arg1, arg2) -> Bool in
            return ( arg1.date.compare( arg2.date ) == .orderedDescending )
        })
    }
    return foundJournals
}

