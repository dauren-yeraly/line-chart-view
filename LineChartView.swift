//
//  LineChartView.swift
//  ChartTest
//
//  Created by Dauren Yeraly on 08.05.2025.
//

import UIKit

protocol LineChartViewDelegate: AnyObject {
    func didSelect(index: Int)
}

final class LineChartView: UIView {
    
    // MARK: - Types
    
    private enum Constants {
        static let topSpace: CGFloat = 40.0
        static let bottomSpace: CGFloat = 40.0
        static let startingX: CGFloat = 40
        static let numberOfLines = 5
    }
    
    // MARK: - Properties
    
    weak var delegate: LineChartViewDelegate?
    
    var configuration: Configuration = .empty {
        didSet {
            guard oldValue != configuration else { return }
            setNeedsLayout()
        }
    }
    
    private let dataLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    private let gridLayer = CALayer()
    
    private var points: [CGPoint] = []
    private var linePath: UIBezierPath?
    
    // MARK: - Layers & Views
    
    private var dotView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()
    
    private var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let tooltipLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.layer.cornerRadius = 4
        label.textAlignment = .center
        label.layer.masksToBounds = true
        return label
    }()
    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupTooltip()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
             
        guard configuration.entries.isEmpty || points.isEmpty else { return }
        
        clean()
        setupLayers()
        setupPoints()

        drawBackgroundLines()
        drawChart()
        drawGradient()
        drawXAxisLabels()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        layer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(gradientLayer)
        backgroundColor = .white
    }
    
    private func clean() {
        layer.sublayers?.forEach({
            if $0 is CATextLayer {
                $0.removeFromSuperlayer()
            }
        })
        dataLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        gridLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
    }
    
    private func setupLayers() {
        dataLayer.frame = CGRect(
            x: .zero,
            y: Constants.topSpace,
            width: layer.frame.width,
            height: layer.frame.height - Constants.topSpace - Constants.bottomSpace
        )
        gradientLayer.frame = dataLayer.frame
        gridLayer.frame = dataLayer.frame
        
        gradientLayer.colors = configuration.gradientColor
    }
    
    private func setupPoints() {
        points = makePoints(entries: configuration.entries)
    }
    
    // MARK: - Drawing
    
    private func drawBackgroundLines() {
        guard
            let maxEntry = configuration.entries.max()?.value,
            let minEntry = configuration.entries.min()?.value
        else {
            return
        }
        
        let minValue: CGFloat
        let maxValue: CGFloat
        let gridValues: [CGFloat]
        var textValues: [CGFloat] = []
        let numberOfLines = Constants.numberOfLines
        
        if configuration.isSingleEntry || configuration.allEqual {
            var step: CGFloat = 2
            minValue = CGFloat(minEntry) - CGFloat(numberOfLines / 2) * step - 1
            maxValue = minValue + CGFloat(numberOfLines) * step
            gridValues = (.zero...numberOfLines).map { minValue + CGFloat($0) * step }

            if minValue > .zero {
                textValues = gridValues
            } else {
                let midIndex = (CGFloat(numberOfLines) / 2).rounded()
                step = CGFloat(minEntry) / CGFloat(midIndex)
                for i in 1...Int(midIndex) {
                    textValues.insert(CGFloat(minEntry) - CGFloat(i) * step, at: 0)
                    textValues.append(CGFloat(minEntry) + CGFloat(i) * step)
                }
            }
        } else {
            minValue = .init(minEntry)
            maxValue = .init(maxEntry)
            let step = (maxValue - minValue) / CGFloat(numberOfLines)
            gridValues = (.zero...numberOfLines).map { minValue + CGFloat($0) * step }
            textValues = gridValues
        }
        
        gridValues.enumerated().forEach { index, value in
            let invertedYPosition = 1 - (value - minValue) / (maxValue - minValue)
            let height = invertedYPosition * gridLayer.frame.height
            
            let path: UIBezierPath = .init()
            path.move(to: CGPoint(x: Constants.startingX, y: height))
            path.addLine(to: CGPoint(x: gridLayer.frame.width, y: height))
            
            let lineLayer: CAShapeLayer = .init()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = UIColor.separator.cgColor
            lineLayer.lineWidth = 2
            lineLayer.lineDashPattern = index > .zero ? [3, 3] : nil
            gridLayer.addSublayer(lineLayer)
            
            let textLayer: CATextLayer = .init()
            let text = Double(textValues[index]).rounded(toPlaces: 2).description
            let size = text.size(font: .systemFont(ofSize: 12))
            textLayer.frame = .init(origin: .init(x: .zero, y: height - size.height / 2), size: size)
            textLayer.alignmentMode = .left
            textLayer.string = text
            textLayer.font = UIFont.systemFont(ofSize: 12)
            textLayer.fontSize = 12
            textLayer.foregroundColor = UIColor.gray.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            gridLayer.addSublayer(textLayer)
        }
    }

    private func drawChart() {
        guard !configuration.entries.isEmpty else { return }
        let lineLayer = CAShapeLayer()
        lineLayer.path = makeLinePath().cgPath
        lineLayer.lineWidth = 2
        lineLayer.strokeColor = configuration.lineColor.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        dataLayer.addSublayer(lineLayer)
    }
    
    private func drawGradient() {
        guard !points.isEmpty else { return }

        let path = UIBezierPath()

        if configuration.isSingleEntry || configuration.allEqual {
            let singlePoint = points[0]

            path.move(to: CGPoint(x: singlePoint.x, y: dataLayer.frame.height / 2))
            path.addLine(to: CGPoint(x: singlePoint.x, y: singlePoint.y))
            path.addLine(to: CGPoint(x: dataLayer.frame.width, y: singlePoint.y))
            path.addLine(to: CGPoint(x: dataLayer.frame.width, y: dataLayer.frame.height / 2))
        } else {
            path.move(to: CGPoint(x: points[0].x, y: dataLayer.frame.height))
            path.addLine(to: points[0])
            path.append(makeLinePath())
            path.addLine(to: CGPoint(x: points.last!.x, y: dataLayer.frame.height))
            path.addLine(to: CGPoint(x: points[0].x, y: dataLayer.frame.height))
        }

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.lineWidth = 0

        gradientLayer.mask = maskLayer
    }

    private func drawXAxisLabels() {
        let labelWidth: CGFloat = 32
        let labelHeight: CGFloat = 16
        let yPosition = layer.frame.height - Constants.bottomSpace / 2 - labelHeight / 2

        guard let firstX = points.first?.x else { return }
        guard let lastX = points.last?.x else { return }

        let spacing: CGFloat = configuration.isSingleEntry ? 0 : (lastX - firstX - labelWidth) / CGFloat(configuration.entries.count - 1)
        
        for (index, point) in configuration.entries.enumerated() where point.label != nil {
            let xPos = configuration.isSingleEntry ? (layer.frame.width / 2 - labelWidth / 2) : (firstX + spacing * CGFloat(index))

            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: xPos, y: yPosition, width: labelWidth, height: labelHeight)
            textLayer.foregroundColor = UIColor.gray.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
            textLayer.fontSize = 12
            textLayer.string = point.label

            layer.addSublayer(textLayer)
        }
    }
    
    // MARK: - Tooltip

    private func setupTooltip() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)

        addSubview(dotView)
        addSubview(lineView)
        addSubview(tooltipLabel)
    }
    
    private func updateTooltip(at touchPoint: CGPoint) {
        guard !points.isEmpty else {
            return
        }
        
        var closestPoint: CGPoint?
        var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        var selectedIndex: Int?

        for (index, point) in points.enumerated() {
            let distance = abs(point.x - touchPoint.x)
            if distance < minDistance {
                minDistance = distance
                closestPoint = point
                selectedIndex = index
            }
        }

        guard let selectedPoint = closestPoint, let selectedIndex else {
            return
        }
        
        let xPosition: CGFloat = configuration.isSingleEntry ? dataLayer.frame.width / 2 : selectedPoint.x
        let yPosition: CGFloat = configuration.isSingleEntry || configuration.allEqual ? selectedPoint.y / 2 : selectedPoint.y
        
        dotView.frame = CGRect(x: xPosition - 4, y: yPosition + Constants.topSpace - 4, width: 8, height: 8)
        lineView.frame = CGRect(
            x: xPosition - 1,
            y: dataLayer.frame.maxY,
            width: 2,
            height: dotView.frame.origin.y - dataLayer.frame.maxY
        )

        tooltipLabel.text = configuration.entries[selectedIndex].value.description
        tooltipLabel.frame = CGRect(
            x: xPosition - 24,
            y: dotView.frame.minY - tooltipLabel.frame.height,
            width: 48,
            height: 24
        )
        
        delegate?.didSelect(index: selectedIndex)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: self)
        updateTooltip(at: touchPoint)
    }

    @objc private func handlePan(_ gesture: UIGestureRecognizer) {
        let touchPoint = gesture.location(in: self)
        
        if gesture.state == .began || gesture.state == .changed {
            updateTooltip(at: touchPoint)
        }
    }
    
    // MARK: - Factory methods
    
    private func makePoints(entries: [Configuration.Entry]) -> [CGPoint] {
        guard let max = entries.max()?.value, let min = entries.min()?.value, !entries.isEmpty else {
            return []
        }

        let scaledMax = CGFloat(max)
        let minValue = CGFloat(min)
        let verticalRange = (scaledMax > minValue) ? (scaledMax - minValue) : 1

        let availableWidth = self.frame.width - Constants.startingX
        let dynamicLineGap = (entries.count > 1) ? availableWidth / CGFloat(entries.count - 1) : 0

        return entries.enumerated().map { (i, entry) in
            let x = CGFloat(i) * dynamicLineGap + Constants.startingX
            let yPercentage = (verticalRange > 0) ? (CGFloat(entry.value) - minValue) / verticalRange : 0
            let y = dataLayer.frame.height * (1.0 - yPercentage)
            return CGPoint(x: x, y: y)
        }
    }

    private func makeLinePath() -> UIBezierPath {
        guard !configuration.entries.isEmpty else { return .init() }
        
        let path = UIBezierPath()
        
        if configuration.isSingleEntry || configuration.allEqual {
            let middleY = dataLayer.frame.height / 2
            path.move(to: CGPoint(x: Constants.startingX, y: middleY))
            path.addLine(to: CGPoint(x: frame.width, y: middleY))
            return path
        }
        
        path.move(to: points[.zero])
        
        let startingIndex = 1
        
        for i in startingIndex..<points.count {
            let previousPoint = points[i - startingIndex]
            let currentPoint = points[i]
            
            if i < points.count - startingIndex {
                let nextPoint = points[i + startingIndex]
                
                let incomingIsCollinear: Bool = (i >= 2) ? arePointsCollinear(points[i - 2], previousPoint, currentPoint) : false
                let outgoingIsCollinear = arePointsCollinear(previousPoint, currentPoint, nextPoint)
                
                if incomingIsCollinear || outgoingIsCollinear {
                    path.addLine(to: currentPoint)
                } else {
                    let controlPoint1 = CGPoint(
                        x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                        y: previousPoint.y
                    )
                    let controlPoint2 = CGPoint(
                        x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                        y: currentPoint.y
                    )
                    path.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                }
            } else {
                if points.count >= 3 {
                    let thirdLastPoint = points[i - 2]
                    let secondLastPoint = points[i - 1]
                    let lastPoint = points[i]
                    
                    if arePointsCollinear(thirdLastPoint, secondLastPoint, lastPoint) {
                        path.addLine(to: currentPoint)
                    } else {
                        let controlPoint1 = CGPoint(
                            x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                            y: previousPoint.y
                        )
                        let controlPoint2 = CGPoint(
                            x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                            y: currentPoint.y
                        )
                        path.addCurve(to: currentPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                    }
                } else {
                    path.addLine(to: currentPoint)
                }
            }
        }
        self.linePath = path
        return path
    }

    // MARK: - Helpers
    
    private func arePointsCollinear(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> Bool {
        let area = (p1.x * (p2.y - p3.y) +
                    p2.x * (p3.y - p1.y) +
                    p3.x * (p1.y - p2.y)) / 2
        return abs(area) < 1e-6
    }
}
