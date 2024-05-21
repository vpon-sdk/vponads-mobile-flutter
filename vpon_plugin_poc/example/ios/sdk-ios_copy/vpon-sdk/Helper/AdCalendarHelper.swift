//
//  AdCalendarHelper.swift
//  vpon-sdk
//
//  Created by Judy Tsai on 2023/11/7.
//  Copyright © 2023 com.vpon. All rights reserved.
//

import EventKit

struct AdCalendarHelper {
    
    typealias CalendarSuccess = () -> Void
    typealias CalendarFailure = (Error) -> Void
    
    static func addCalendar(calendar: AdCalendar, completion: @escaping CalendarSuccess, failure: @escaping CalendarFailure) {
        guard calendar.canAddCalendar() else {
            DispatchQueue.main.sync {
                failure(ErrorGenerator.addCalendarFailed())
            }
            return
        }
        
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else {
                DispatchQueue.main.sync {
                    failure(ErrorGenerator.addCalendarFailed(errorDescription: error?.localizedDescription))
                }
                return
            }
            let event = EKEvent(eventStore: eventStore)
            event.title = calendar.desc
            event.notes = calendar.summary
            event.location = calendar.locationName
            event.startDate = calendar.startDate
            event.endDate = calendar.endDate
            if calendar.needReminder, let date = calendar.reminderDate {
                let alarm = EKAlarm(absoluteDate: date)
                event.addAlarm(alarm)
            }
            if calendar.needRecurrence, let rule = calendar.recurrence {
                event.recurrenceRules = [rule]
            }
            event.calendar = eventStore.defaultCalendarForNewEvents
            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.sync {
                    completion()
                }
            } catch {
                DispatchQueue.main.sync {
                    failure(ErrorGenerator.addCalendarFailed(errorDescription: error.localizedDescription))
                }
            }
        }
    }
}
