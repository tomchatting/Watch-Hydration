//
//  ComplicationController.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 21/05/2025.
//

// ComplicationController.swift
import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.thomaschatting.Watch-Hydration.Shared") ?? UserDefaults.standard
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.thomaschatting.Watch-Hydration.watchkitapp.HydrationWidget",
                displayName: "Hydration Progress",
                supportedFamilies: [
                    .circularSmall,
                    .graphicCircular,
                    .graphicCorner,
                    .graphicBezel
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these complications
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        handler(endOfDay)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let total = sharedDefaults.double(forKey: "hydrationTotal")
        let goal = sharedDefaults.double(forKey: "hydrationGoal") > 0 ? sharedDefaults.double(forKey: "hydrationGoal") : 2000
        
        print("Complication reading values - Total: \(total), Goal: \(goal)")
        
        // Create the complication template based on family
        var template: CLKComplicationTemplate?
        
        let progressPercent = Float(min(total / goal, 1.0))
        
        switch complication.family {
        case .circularSmall:
            let percentProvider = CLKSimpleTextProvider(text: "\(Int(progressPercent * 100))%")
            template = CLKComplicationTemplateCircularSmallRingText(
                textProvider: percentProvider,
                fillFraction: progressPercent,
                ringStyle: .closed
            )
            
        case .graphicCircular:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: UIColor.blue,
                fillFraction: progressPercent
            )
            
            let percentText = "\(Int(progressPercent * 100))%"
            let percentProvider = CLKSimpleTextProvider(text: percentText)
            
            template = CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: gaugeProvider,
                centerTextProvider: percentProvider
            )
            
        case .graphicCorner:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: UIColor.blue,
                fillFraction: progressPercent
            )
            
            let textProvider = CLKSimpleTextProvider(
                text: "\(Int(progressPercent * 100))%"
            )
            
            let emptyTextProvider = CLKSimpleTextProvider(text: "")
            
            template = CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: gaugeProvider,
                leadingTextProvider: emptyTextProvider,
                trailingTextProvider: textProvider,
                outerTextProvider: emptyTextProvider
            )
            
        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeImage(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: UIColor.blue,
                    fillFraction: progressPercent
                ),
                imageProvider: CLKFullColorImageProvider(
                    fullColorImage: UIImage(systemName: "drop.fill")!
                )
            )
            
            let textProvider = CLKSimpleTextProvider(
                text: "\(Int(total)) / \(Int(goal)) mL"
            )
            
            template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: circularTemplate,
                textProvider: textProvider
            )
            
        default:
            // Unsupported family
            break
        }
        
        if let validTemplate = template {
            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: validTemplate
            )
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate?
        
        let progressPercent: Float = 0.75
        
        switch complication.family {
        case .circularSmall:
            let percentProvider = CLKSimpleTextProvider(text: "75%")
            template = CLKComplicationTemplateCircularSmallRingText(
                textProvider: percentProvider,
                fillFraction: progressPercent,
                ringStyle: .closed
            )
            
        case .graphicCircular:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: UIColor.blue,
                fillFraction: progressPercent
            )
            
            let percentProvider = CLKSimpleTextProvider(text: "75%")
            
            template = CLKComplicationTemplateGraphicCircularClosedGaugeText(
                gaugeProvider: gaugeProvider,
                centerTextProvider: percentProvider
            )
            
        case .graphicCorner:
            let gaugeProvider = CLKSimpleGaugeProvider(
                style: .fill,
                gaugeColor: UIColor.blue,
                fillFraction: progressPercent
            )
            
            let textProvider = CLKSimpleTextProvider(
                text: "75%"
            )
            
            // Use empty text provider instead of nil
            let emptyTextProvider = CLKSimpleTextProvider(text: "")
            
            template = CLKComplicationTemplateGraphicCornerGaugeText(
                gaugeProvider: gaugeProvider,
                leadingTextProvider: emptyTextProvider,
                trailingTextProvider: textProvider,
                outerTextProvider: emptyTextProvider
            )
            
        case .graphicBezel:
            let circularTemplate = CLKComplicationTemplateGraphicCircularClosedGaugeImage(
                gaugeProvider: CLKSimpleGaugeProvider(
                    style: .fill,
                    gaugeColor: UIColor.blue,
                    fillFraction: progressPercent
                ),
                imageProvider: CLKFullColorImageProvider(
                    fullColorImage: UIImage(systemName: "drop.fill")!
                )
            )
            
            let textProvider = CLKSimpleTextProvider(
                text: "1500 / 2000 mL"
            )
            
            template = CLKComplicationTemplateGraphicBezelCircularText(
                circularTemplate: circularTemplate,
                textProvider: textProvider
            )
            
        default:
            // Unsupported family
            break
        }
        
        handler(template)
    }
}
