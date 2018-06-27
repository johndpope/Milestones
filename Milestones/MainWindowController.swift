//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  MainWindowController.swift
//  Milestones
//
//  Copyright © 2016 Altay Cebe. All rights reserved.
//

import Foundation
import Cocoa


 struct VCDependency: Dependencies {
    
    var xCalculator: HorizontalCalculator
    var yCalculator: VerticalCalculator
    var stateModel: StateProtocol

}

class MainWindowController :NSWindowController, StateObserverProtocol {

    @IBOutlet var groupPopUpButton :NSPopUpButton!

    
    private var timelineHorizontalCalculator = TimelineCalculator(lengthOfDay: 30)
    private var timelineVerticalCalculator = TimelinePositioner(heightOfTimeline: 100)

    private var dependencies :VCDependency?
    
    override var document: AnyObject? {

        didSet {
            if document != nil {

                updateViewControllers()
                updateGroupPopUpButton()

                dependency()?.stateModel.remove(dataObserver: self)
                dependency()?.stateModel.add(dataObserver: self)
                
                shouldCloseDocument = true

            }
        }
    }


    private func dependency() -> Dependencies? {

        guard let model = (document as? Document)?.dataModel else {return nil}
        let newDependency = VCDependency(xCalculator: timelineHorizontalCalculator, yCalculator: timelineVerticalCalculator, stateModel : model)
        return newDependency
    }
    
    
    private func updateViewControllers() {
        
        if let cVC = contentViewController  {
            cVC.representedObject = dependency()
        }
    }
    
    //MARK: Sheet Handling
    func showExportSheet() {
        
        //This casting chain is a workaround (?): https://bugs.swift.org/browse/SR-3871
        guard let calculators = dependency() as? HasCalculators else {return}
        guard let activeGroup = dependency()?.stateModel.selectedGroup else {return}
        guard let milestones = activeGroup.fetchAllMilestones() else {return}
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "MainStoryboard"), bundle: nil)
        guard let exportPanelViewController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "ExportPanelViewController")) as? ExportPanelViewController else {return}
        
        
        //Configure the exportPanel
        let exportPanel = NSSavePanel()
        exportPanel.message = "Export Pfad wählen"
        exportPanel.allowedFileTypes = ["pdf"]
        exportPanel.prompt = "Export"
        exportPanel.nameFieldStringValue = activeGroup.exportInfo?.fileName ?? "Untitled"

        exportPanel.accessoryView = exportPanelViewController.view
        
        //FIXME: The following calls only work if the ExportPanelViewController view is loaded
        let firstMilestone = activeGroup.exportInfo?.startMilestone ?? milestones.first
        let lastMilestone = activeGroup.exportInfo?.endMilestone ?? milestones.last
        exportPanelViewController.setMilestones(milestones: milestones, withStartMilestone: firstMilestone, endMilestone: lastMilestone)
        exportPanelViewController.titleForExport = activeGroup.exportInfo?.title ?? activeGroup.name ?? ""
        exportPanelViewController.descriptionForExport = activeGroup.exportInfo?.info ?? ""
        
        
        exportPanel.beginSheetModal(for: window!, completionHandler: {(value: NSApplication.ModalResponse) in
            
            if (value ==  NSApplication.ModalResponse.continue) {
                
                if let startDate = exportPanelViewController.selectedStartMilestone?.date,
                    let endDate = exportPanelViewController.selectedEndMilestone?.date,
                    let url = exportPanel.url {
                    
                    let exporter = Exporter(dependencies: calculators)
                    let type = Zoom().zoomTypeForLenghtOfDay(length: calculators.xCalculator.lengthOfDay)
                    exporter.exportGroup(group: activeGroup, asType: type, fromDate: startDate, toDate: endDate, toFileAtURL: url)
                    
                    //Store the export parameters
                    activeGroup.exportInfo?.title = exportPanelViewController.titleForExport
                    activeGroup.exportInfo?.info = exportPanelViewController.descriptionForExport
                    activeGroup.exportInfo?.startMilestone = exportPanelViewController.selectedStartMilestone
                    activeGroup.exportInfo?.endMilestone = exportPanelViewController.selectedEndMilestone
                    activeGroup.exportInfo?.fileName = exportPanel.nameFieldStringValue
                }
            }
            
        })
    }
  
    //MARK: Window life cycle
    override func windowDidLoad() {
        
        // Setting the windows autosavename with the Storyboard somehow doesn't work. Setting the autosavename programmatically however restores the window to its proper size
        
        shouldCascadeWindows = false
        window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "MainWindow"))
        super.windowDidLoad()
    }
    
    //MARK: Update
    private func updateGroupPopUpButton(){

        guard let groups = dependency()?.stateModel.allGroups() else {return}

        groupPopUpButton.removeAllItems()

        var idx = 0
        for aGroup in groups {

            if let groupName = aGroup.name {

                //Instead of simply using groupPopUpButton.addItem(withTitle: groupName) we have to use the method below the NSPopOverButton. Otherwise there will be no entries with the same name 
                let newMenuItem = NSMenuItem(title: groupName, action: #selector(onClickOfGroupPopUpButton), keyEquivalent: String(idx + 1))
                newMenuItem.target = self
                groupPopUpButton.menu?.addItem(newMenuItem)
                
                idx += 1
                
            }
        }
        
        let separatorItem = NSMenuItem.separator()
        let manageGroupsItem = NSMenuItem(title: "Gruppen verwalten", action: #selector(onClickOfManageGroupsPopUpButton), keyEquivalent: "")
        groupPopUpButton.menu?.addItem(separatorItem)
        groupPopUpButton.menu?.addItem(manageGroupsItem)

        
        //Select the active group
        if let activeGroup = dependency()?.stateModel.selectedGroup {

            if let index = groups.index(of: activeGroup ) {

                groupPopUpButton.selectItem(at: index)
            }
        }
    }

    //MARK: UI Callbacks
    @IBAction func onClickOfGroupPopUpButton(_ sender: NSPopUpButton) {

        dependency()?.stateModel.selectedGroup = currentlySelectedGroup()
    }
    
    @objc func onClickOfManageGroupsPopUpButton(_ sender: NSPopUpButton) {

        groupPopUpButton.select(nil)
       let groupsManagementViewController = NSStoryboard(name: NSStoryboard.Name(rawValue: "MainStoryboard"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "GroupsmanagementViewController")) as! GroupsmanagementViewController
        groupsManagementViewController.originalManagedObjectContext = self.document?.managedObjectContext
        
        self.window?.contentViewController?.presentViewControllerAsSheet(groupsManagementViewController)
    }
    
    @IBAction func onClickOfExportButton(_ sender: Any) {
        showExportSheet()
        
    }
    

    //MARK: DataObserverProtocol
    func didChangeSelectedGroup(_ group :Group?) {
        updateGroupPopUpButton()
    }

    func didChangeSelectedTimeline(_ selectedTimelines :[Timeline]) {
    }
    func didChangeSelectedMilestone(_ milestone :Milestone?){
    }

    //MARK: Helper
    private func currentlySelectedGroup() -> Group? {

        guard let allGroups = dependency()?.stateModel.allGroups() else { return nil }

        var selectedGroup :Group?
        if groupPopUpButton.indexOfSelectedItem >= 0 {

            selectedGroup = allGroups[groupPopUpButton.indexOfSelectedItem]
        }

        return selectedGroup
    }

}