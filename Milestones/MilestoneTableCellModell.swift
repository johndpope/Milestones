//
//  MilestoneCellModell.swift
//  Milestones
//
//  Created by Altay Cebe on 24.12.18.
//  Copyright © 2018 Altay Cebe. All rights reserved.
//

import Foundation
import Cocoa

struct MilestoneTableCellModel : MilestoneTableCellDataSourceProtocol {
    
    private let calendarWeekDateFormatter :DateFormatter = DateFormatter()
    private let dateFormatter :DateFormatter = DateFormatter()
    
    private(set) var dateString: String = ""
    private(set) var cwString: String = ""
    private(set) var nameString: String = ""
    private(set) var timeIntervallString: String = ""
    private(set) var needsExpandedCell: Bool = false
    private(set) var iconGraphic: IconGraphic
    
    
    init(milestone: Milestone, nextDate :Date? = nil) {
        calendarWeekDateFormatter.dateFormat = "w.e/yy"
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = milestone.date {
            dateString = dateFormatter.string(from: date)
            cwString = "KW " + calendarWeekDateFormatter.string(from: date)
            
            if let date2 = nextDate {
                let dateInterval = DateInterval(start: date, end: date2)
                if dateInterval.isDurationLongerThanOneDay() {
                    needsExpandedCell = true
                    let timeIntervalFormatter = TimeIntervalFormatter(startDate: date, endDate: date2)
                    timeIntervallString = timeIntervalFormatter.intervalString()
                }
            }
        }
        
        nameString = milestone.name ?? ""
        
        let iconType = IconType(rawValue: milestone.type.intValue) ?? .Diamond
        let iconColor = milestone.timeline?.color ?? .black
        iconGraphic = IconGraphic(type: iconType)
        iconGraphic.fillColor = iconColor
        iconGraphic.isDrawingFill = true
    }

    init(adjustment: Adjustment, nextDate :Date? = nil) {
        calendarWeekDateFormatter.dateFormat = "w.e/yy"
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = adjustment.date {
            
            dateString = dateFormatter.string(from: date)
            cwString = "KW " + calendarWeekDateFormatter.string(from: date)
            
            if let date2 = nextDate {
                let dateInterval = DateInterval(start: date, end: date2)
                if dateInterval.isDurationLongerThanOneDay() {
                    needsExpandedCell = true
                    let timeIntervalFormatter = TimeIntervalFormatter(startDate: date, endDate: date2)
                    timeIntervallString = timeIntervalFormatter.intervalString()
                }
            }
        }
        
        let iconType = IconType(rawValue: adjustment.milestone?.type.intValue ?? 0) ?? .Diamond
        iconGraphic = IconGraphic(type: iconType)
        iconGraphic.isDrawingFill = false
        iconGraphic.isDrawingStroke  = true
        iconGraphic.strokeWidth = 2.0
    }

}
