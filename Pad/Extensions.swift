//
//  Extensions.swift
//  Pad
//
//  Created by Colin Dunn on 4/27/15.
//  Copyright (c) 2015 Colin Dunn. All rights reserved.
//

import UIKit
import CloudKit

let atlas = UIFont(name: "AtlasGrotesk-Regular", size: 16)

class Extensions: NSObject {}

extension CKRecord: Equatable {}
public func ==( lhs: CKRecord, rhs: CKRecord ) -> Bool {
    return lhs.recordID == rhs.recordID
}

extension NSDate {
    func yearsFrom(date:NSDate)   -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitYear, fromDate: date, toDate: self, options: nil).year }
    func monthsFrom(date:NSDate)  -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMonth, fromDate: date, toDate: self, options: nil).month }
    func weeksFrom(date:NSDate)   -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekOfYear, fromDate: date, toDate: self, options: nil).weekOfYear }
    func daysFrom(date:NSDate)    -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitDay, fromDate: date, toDate: self, options: nil).day }
    func hoursFrom(date:NSDate)   -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitHour, fromDate: date, toDate: self, options: nil).hour }
    func minutesFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMinute, fromDate: date, toDate: self, options: nil).minute }
    func secondsFrom(date:NSDate) -> Int { return NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitSecond, fromDate: date, toDate: self, options: nil).second }
    var relativeTime: String {
        if NSDate().yearsFrom(self)  > 0 {
            return NSDate().yearsFrom(self).description  + "y"
        }
        if NSDate().monthsFrom(self) > 0 {
            return NSDate().monthsFrom(self).description + "m"
        }
        if NSDate().weeksFrom(self) > 0 { return NSDate().weeksFrom(self).description  + "w"
        }
        if NSDate().daysFrom(self) > 0 {
            if NSDate().daysFrom(self) == 1 { return "Yesterday" }
            return NSDate().daysFrom(self).description + "d"
        }
        if NSDate().hoursFrom(self)   > 0 {
            return "\(NSDate().hoursFrom(self))h"
        }
        if NSDate().minutesFrom(self) > 0 {
            return "\(NSDate().minutesFrom(self))m"
        }
        if NSDate().secondsFrom(self) > 0 {
            if NSDate().secondsFrom(self) < 60 { return "Just now" }
            return "\(NSDate().secondsFrom(self))s"
        }
        return ""
    }
}