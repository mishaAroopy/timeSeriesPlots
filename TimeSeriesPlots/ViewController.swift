//
//  ViewController.swift
//  TimeSeriesPlots
//
//  This is an extension of the CorePlot examples created by Eric Skroch in his CorePlot Repository
//  The extension provides 
// (a) automated formatting for the date/time labels on the x-axis upon pinch-zooming the x-axis
// (b) highlighting of a curve upon tapping a data point on a curve

/* Incorporating CorePlot into a project (these steps are almost verbatim from the CorePlot documentation)
    https://github.com/core-plot/core-plot/wiki/Using-Core-Plot-in-an-Application
 
    Step 1: Drag the CorePlot.xcodeproj bundle into your application's Xcode project (without copying the file).
 
    Step 2: Show the project navigator in the left-hand list and click on your project.
    Select your application target from under the "Targets" source list that appears. Click on the "Build Phases" tab and expand the "Target Dependencies" group. Click on the plus button, select the CorePlot-CocoaTouch library, and click Add. This should ensure that the Core Plot library will be built with your application.

    Step 3: Core Plot is built as a static library for iPhone, so you'll need to drag the libCorePlot-CocoaTouch.a static library from under the CorePlot-CocoaTouch.xcodeproj group to the "Link Binaries With Libraries" group within the application target's "Build Phases" group
 
    Step 4: You'll also need to point to the right header location. Under your Build settings, set the Header Search Paths to the relative path from your application to the framework/ subdirectory within the Core Plot source tree. Make sure to make this header search path recursive.
 
    Step 5:You need to add -ObjC to Other Linker Flags as well (as of Xcode 4.2, -all_load does not seem to be needed, but it may be required for older Xcode versions; it must be removed when using Xcode 5.1 or later).
 
    Step6:Core Plot is based on Core Animation, so if you haven't already, add the QuartzCore framework to your application project. With releases 2.0 to 2.2, the Accelerate framework is also required.
 
    Step 7: Finally, you should be able to import all of the Core Plot classes and data types by adding the following line to the bridging header.
        #import "CorePlot-CocoaTouch.h"
 
        To create a bridging header: File > New > File > (iOS, watchOS, tvOS, or macOS) > Source > Header File.
        Name your file “YourProjectName-Bridging-Header.h”
 
    Step 8: Make sure the Swift Compiler can see the bridging header. Under Build Settings make sure the
        Objective-C Bridging Header  has “YourProjectName/YourProjectName-Bridging-Header.h”
 
    Step 9: in Storyboard add a UIView to the viewcontroller, then change its class to "CPTGraphHostingView"
*/
import UIKit

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    fileprivate var graph : CPTXYGraph? = nil
    var bigGraph = CPTXYGraph(frame: CGRect.zero)
    var allPlotData = [String: [(Double, Double)]]()
    var highlightData = [(Double,Double)]()
    var nameTagsForColors = [String]()
    
    var plotColoursArray = [
        CPTColor(componentRed: CGFloat(0.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: 1.0),
        CPTColor(componentRed: CGFloat(1.0), green: CGFloat(0.0), blue: CGFloat(1.0), alpha: 1.0),
        CPTColor(componentRed: CGFloat(1.0), green: 0.0, blue: 1.0, alpha:1.0),
    ]
    var plotDimColoursArray = [
        CPTColor(componentRed: CGFloat(0.0), green: CGFloat(1.0), blue: CGFloat(1.0), alpha: 0.3),
        CPTColor(componentRed: CGFloat(1.0), green: CGFloat(0.0), blue: CGFloat(1.0), alpha: 0.3),
        CPTColor(componentRed: CGFloat(1.0), green: 0.0, blue: 1.0, alpha: 0.3),
    ]
    var refDate = Date()
    var refDate_Double = Double( Date().timeIntervalSinceReferenceDate )
    
    var initglobalPlotSpace_X_Range = CPTPlotRange(location:  NSNumber(value: 0.0 * 60 * 60), length: NSNumber(  value: 30.0 * 24 * 60 * 60) )
    var initglobalMajorIntervalLength = 24.0 * 60 * 60 * 4.0
    var initglobalPlotSpace_Y_Range = CPTPlotRange(location:-3.0, length:14.0)
    var myAnnotation: CPTPlotSpaceAnnotation?
    
    @IBAction func resetButtonPressed(_ sender: AnyObject) {
        let plotSpace = graphView.hostedGraph!.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = initglobalPlotSpace_X_Range
        plotSpace.yRange = initglobalPlotSpace_Y_Range
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let theme = CPTTheme(named: CPTThemeName.darkGradientTheme)
        bigGraph.apply(theme)
        bigGraph.paddingTop = 0
        bigGraph.paddingBottom = 0.0
        bigGraph.paddingLeft = 0.0
        bigGraph.paddingRight = 0.0
        
        if let host = self.graphView {
            host.hostedGraph = bigGraph;
        }
        
        let plotSpace = bigGraph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = initglobalPlotSpace_X_Range
        plotSpace.yRange = initglobalPlotSpace_Y_Range
        plotSpace.allowsUserInteraction = true
        plotSpace.delegate = self
        
        let whiteDashedLineStyle               = CPTMutableLineStyle()
        whiteDashedLineStyle.lineWidth         = 1.0
        whiteDashedLineStyle.lineColor         = CPTColor.gray()
        whiteDashedLineStyle.dashPattern       = [3.0, 8.0]
        
        let axisSet = bigGraph.axisSet as! CPTXYAxisSet
        if let x = axisSet.xAxis {
            x.majorIntervalLength   = initglobalMajorIntervalLength as NSNumber?
            x.orthogonalPosition    = 0.0
            x.minorTicksPerInterval = 4
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd"
            let timeFormatter = CPTTimeFormatter(dateFormatter:dateFormatter)
            timeFormatter.referenceDate = refDate;
            x.labelFormatter            = timeFormatter;
            //x.labelRotation = CGFloat(M_PI_2)
            //x.labelingPolicy = .Automatic
            x.majorGridLineStyle = whiteDashedLineStyle
        }
        
        if let y = axisSet.yAxis {
            y.majorIntervalLength   = 0.5
            y.minorTicksPerInterval = 5
            y.orthogonalPosition    = 0
            y.labelingPolicy = .automatic
            y.majorGridLineStyle = whiteDashedLineStyle
            y.axisConstraints = CPTConstraints.constraint(withLowerOffset: 50.0) // this seems to pin the YAxis in the same place
            // regardless of how we zoom and pan the X-Axis.
            y.labelExclusionRanges = [CPTPlotRange(location:-11.0, length:10.5)]
        }
        self.graph = bigGraph
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let thirtydaysAgo = Date().addingTimeInterval( -30.0 * 24.0 * 60.0 * 60.0 )
        refDate = thirtydaysAgo
        refDate_Double = Double( refDate.timeIntervalSinceReferenceDate )
        
        let testdt_today_double = Double( NSDate().timeIntervalSinceReferenceDate )
        let yesterday   = NSDate().addingTimeInterval( -1.0 * 24.0 * 60.0 * 60.0 )
        let fiveDaysAgo = NSDate().addingTimeInterval( -5.0 * 24.0 * 60.0 * 60.0 )
        
        let testdt_yesterday_double = Double( yesterday.timeIntervalSinceReferenceDate )
        let testdt_fiveDaysAgo_double = Double( fiveDaysAgo.timeIntervalSinceReferenceDate )
        
        let myLabel = "data1"
        allPlotData[myLabel] = [( testdt_fiveDaysAgo_double, 3), (testdt_yesterday_double, 2),(testdt_today_double, 4) ]
        nameTagsForColors.append(myLabel)
        let newplot = createNewScatterPlot( allPlotData[ myLabel ]!, plotlabel: myLabel, noLine: false )
        newplot.delegate = self
        bigGraph.add( newplot )
        
        let myLabel1 = "data2"
        allPlotData[myLabel1] = [( testdt_fiveDaysAgo_double, 8), (testdt_yesterday_double, 7),(testdt_today_double, 6) ]
        nameTagsForColors.append(myLabel1)
        let newplot1 = createNewScatterPlot( allPlotData[ myLabel1 ]!, plotlabel: myLabel1, noLine: false )
        newplot1.delegate = self
        bigGraph.add( newplot1 )
    }
}
extension ViewController: CPTPlotDataSource, CPTPlotDelegate, CPTPlotSpaceDelegate{
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        let plotID = plot.identifier as! String
        return UInt( allPlotData[ plotID ]!.count )
    }
    func numberForPlot(_ plot: CPTPlot, field: UInt, recordIndex: UInt) -> AnyObject? {
        let plotID = plot.identifier as! String
        let foundTuple = allPlotData[ plotID ]![ Int(recordIndex) ]
        switch CPTScatterPlotField(rawValue: Int(field))! {
        case .X:
            //convert foundTuple.0 which is the number of seconds since Apple's Reference Date
            //by subtracting how many seconds since Apple's Ref Date, our plot start date is!
            return( (foundTuple.0 - refDate_Double ) ) as NSNumber
        case .Y:
            return( foundTuple.1 ) as NSNumber
        }
    }
    func dataLabel(for plot: CPTPlot, record idx: UInt) -> CPTLayer? {
        var myCPTLayer = CPTTextLayer(text: "")
        let plotID = plot.identifier as! String
        if( idx == UInt(0) ){
            myCPTLayer = CPTTextLayer(text: plotID )
            let myTextStyle = CPTMutableTextStyle()
            myTextStyle.color = plotColourFor(plotID)
            myCPTLayer.textStyle = myTextStyle
        }
        return myCPTLayer
    }
    // Now we change the PlotSpace Delegate function that gets called when we zoom - to only zoom in the X-Axis!
    func plotSpace(_ space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, for coordinate: CPTCoordinate) -> CPTPlotRange? {
        let oneDay : Double = 24 * 60 * 60
        let oneHour: Double = 60 * 60
        var updatedRange = CPTPlotRange()
        switch ( coordinate ) {
        case .X:
            if (newRange.locationDouble < 0.0) {
                let mutableRange = newRange.mutableCopy() as! CPTMutablePlotRange
                updatedRange = mutableRange;
            } else {
                updatedRange = newRange;
            }
            let axisSet = space.graph!.axisSet as! CPTXYAxisSet
            let dateFormatter = DateFormatter()
            if( updatedRange.lengthDouble > 12.0 * oneDay ){
                axisSet.xAxis!.majorIntervalLength = NSNumber(  value: 4.0 * oneDay )
                dateFormatter.dateFormat = "MMM dd"
            } else if( updatedRange.lengthDouble > 5.0 * oneDay ){
                axisSet.xAxis!.majorIntervalLength = NSNumber( value: 2.0 * oneDay )
                dateFormatter.dateFormat = "MMM dd"
            } else if( updatedRange.lengthDouble > 2.0 * oneDay ){
                axisSet.xAxis!.majorIntervalLength = oneDay as NSNumber?
                dateFormatter.dateFormat = "MMM dd"
                let timeFormatter = CPTTimeFormatter(dateFormatter:dateFormatter)
                timeFormatter.referenceDate = refDate;
                axisSet.xAxis!.labelFormatter = timeFormatter;
            } else if( updatedRange.lengthDouble > 20.0 * oneHour ){
                axisSet.xAxis!.majorIntervalLength = NSNumber( value: 12.0 * oneHour )
                dateFormatter.dateFormat = "MMM dd\nh a"
            } else if( updatedRange.lengthDouble > 8.0 * oneHour ){
                axisSet.xAxis!.majorIntervalLength = NSNumber( value: 4.0 * oneHour )
                dateFormatter.dateFormat = "MMM dd\nh a"
            } else{
                axisSet.xAxis!.majorIntervalLength = NSNumber( value: 2.0 * oneHour )
                dateFormatter.dateFormat = "MMM dd\nh:00 a"
            }
            let timeFormatter = CPTTimeFormatter(dateFormatter:dateFormatter)
            timeFormatter.referenceDate = refDate;
            axisSet.xAxis!.labelFormatter = timeFormatter;
            break;
        default:
            updatedRange = ( space as! CPTXYPlotSpace ).yRange
            break;
        }
        return updatedRange;
    }
    
    // MARK: CorePlot creation functions! :-D
    func createNewScatterPlot( _ dataIn: [(Double, Double)], plotlabel: String, noLine: Bool ) -> CPTScatterPlot{
        let dataSourceLinePlotnew = CPTScatterPlot(frame: CGRect.zero)
        dataSourceLinePlotnew.identifier = plotlabel as (NSCoding & NSCopying & NSObjectProtocol)?
        if let lineStyle = dataSourceLinePlotnew.dataLineStyle?.mutableCopy() as? CPTMutableLineStyle {
            lineStyle.lineWidth              = 1.0
            lineStyle.lineColor = plotColourFor(plotlabel)
            lineStyle.lineWidth              = 2.0
            let plotSymbol = CPTPlotSymbol.diamond()
            plotSymbol.lineStyle = lineStyle
            plotSymbol.size = CGSize(width: 12.0 , height: 12.0)
            dataSourceLinePlotnew.plotSymbol = plotSymbol
            if( noLine ){
                dataSourceLinePlotnew.plotSymbol?.size = CGSize(width: 8.0 , height: 8.0)
                lineStyle.lineWidth = 0.0
            }
            dataSourceLinePlotnew.dataLineStyle = lineStyle
        }
        dataSourceLinePlotnew.dataSource = self
        dataSourceLinePlotnew.plotSymbolMarginForHitDetection = 10.0
        return dataSourceLinePlotnew
    }
    
    func createNewBarPlot( _ dataIn: [(Double, Double)], plotlabel: String, thin: Bool ) -> CPTBarPlot{
        let barPlot = CPTBarPlot(frame: CGRect.zero)
        barPlot.identifier = plotlabel as (NSCoding & NSCopying & NSObjectProtocol)?
        if let lineStyle = barPlot.lineStyle?.mutableCopy() as? CPTMutableLineStyle {
            lineStyle.lineWidth              = 1.0
            var fillColor: CPTColor
            lineStyle.lineColor = plotColourFor(plotlabel)
            fillColor = plotColourFor(plotlabel)
            barPlot.barWidthsAreInViewCoordinates = false
            barPlot.barWidth = NSNumber(value: 16.0 * 60.0 * 60.0);
            barPlot.lineStyle = lineStyle
            barPlot.fill = CPTFill( color: fillColor )
        }
        barPlot.dataSource = self
        return barPlot
    }
    
    func scatterPlot( _ plot: CPTScatterPlot, plotSymbolWasSelectedAtRecordIndex idx: UInt ){
        let Yval = numberForPlot(plot, field: UInt(1), recordIndex: idx) as! NSNumber
        let Xval = numberForPlot(plot, field: UInt(0), recordIndex: idx) as! NSNumber
        let plotID = String(describing: plot.identifier!)
            let style = CPTMutableTextStyle()
            style.fontSize = 12.0
            style.fontName = "HelveticaNeue-Bold"
            style.color = plot.dataLineStyle?.lineColor
            myAnnotation?.annotationHostLayer?.removeAnnotation(myAnnotation)
            myAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace!, anchorPlotPoint: [0,0])
            let textLayer = CPTTextLayer(text: plotID, style: style)
            myAnnotation!.contentLayer = textLayer
            myAnnotation!.anchorPlotPoint = [Xval, Yval]
            myAnnotation!.displacement = CGPoint( x: 15, y: 15 )
            
            guard let plotArea = plot.graph?.plotAreaFrame?.plotArea else { return }
            plotArea.addAnnotation(myAnnotation)
            plot.plotSymbol?.size = CGSize(width: 5.0 , height: 5.0)
            highlightOutputCurve(plot)
            plot.graph?.reloadData()
            let delay = 2.0 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.resetOutputCurves(plot)
                plot.plotSymbol?.size = CGSize(width: 5.0 , height: 5.0)
                plot.graph?.reloadData()
            })
    }
    
    func highlightOutputCurve( _ plot: CPTScatterPlot ){
        for eachPlot in (plot.graph?.allPlots())! {
            let isHighlight = ( eachPlot.identifier as! String).lowercased().range( of: "highlight" )
            if( isHighlight == nil ){
                let chgPlot = eachPlot as! CPTScatterPlot
                let thisPlotID = String( describing: chgPlot.identifier! )
                if( chgPlot != plot ) {
                    if let lineStyle = chgPlot.dataLineStyle?.mutableCopy() as? CPTMutableLineStyle {
                        lineStyle.lineWidth              = 1.0
                        lineStyle.lineColor = plotDimColourFor(thisPlotID)
                        let plotSymbol = CPTPlotSymbol.ellipse()
                        plotSymbol.lineStyle = lineStyle
                        plotSymbol.size = CGSize(width: 5.0, height: 5.0 )
                        chgPlot.plotSymbol = plotSymbol
                        chgPlot.dataLineStyle = lineStyle
                    }
                }
            }
        }
    }
    
    func resetOutputCurves( _ plot: CPTScatterPlot ){
        for eachPlot in (plot.graph?.allPlots())! {
            let isHighlight = ( eachPlot.identifier as! String).lowercased().range( of: "highlight" )
            if( isHighlight == nil ){
                let chgPlot = eachPlot as! CPTScatterPlot
                let thisPlotID = String( describing: chgPlot.identifier! )
                    if let lineStyle = chgPlot.dataLineStyle?.mutableCopy() as? CPTMutableLineStyle {
                        lineStyle.lineWidth              = 1.0
                        lineStyle.lineColor = plotColourFor(thisPlotID)
                        let plotSymbol = CPTPlotSymbol.ellipse()
                        plotSymbol.lineStyle = lineStyle
                        plotSymbol.size = CGSize(width: 5.0, height: 5.0 )
                        chgPlot.plotSymbol = plotSymbol
                        chgPlot.dataLineStyle = lineStyle
                    }
            }
        }
    }
    func plotColourFor( _ name: String ) -> CPTColor {
        let thisIndex = nameTagsForColors.index( of: name )
        let wrapNumber = thisIndex! % plotColoursArray.count
        return plotColoursArray[ wrapNumber ]
    }
    func plotDimColourFor( _ name: String ) -> CPTColor {
        let thisIndex = nameTagsForColors.index( of: name )
        let wrapNumber = thisIndex! % plotDimColoursArray.count
        return plotDimColoursArray[ wrapNumber ]
        
    }
}



