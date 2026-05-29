//
//  CustomSliderView.swift
//  MusicApp
//
//  Created by Nhat on 8/23/23.
//

import SwiftUI
import UIKit

struct CustomSliderView: View {
    // MARK: - PROPERTIES WRAPPER
    @Binding var value: Double
    @Binding var isDragSliderView: Bool
    
    // MARK: - PROPERTIES
    var minValue: Double
    var maxValue: Double
    var trackColor: Color
    var progressColor: Color
    let onCompletedDrag: (Double) -> Void
    
    // MARK: - CONSTANTS
    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 12
    
    var body: some View {
        HStack {
            sliderContent
        }
        .frame(minHeight: 12, idealHeight: 12, maxHeight: .infinity) // Auto height với minimum
    }
    
    private var sliderContent: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Spacer()
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(trackColor)
                        .frame(height: trackHeight)
                    
                    // Progress
                    Capsule()
                        .fill(progressColor)
                        .frame(width: progressWidth(geometry: geometry), height: trackHeight)
                    
                    // Thumb — grows while dragging for a tactile feel
                    Circle()
                        .fill(progressColor)
                        .frame(width: thumbSize, height: thumbSize)
                        .scaleEffect(isDragSliderView ? 1.6 : 1.0)
                        .shadow(color: progressColor.opacity(0.5),
                                radius: isDragSliderView ? 6 : 0)
                        .animation(MotionToken.springSnappy, value: isDragSliderView)
                        .offset(x: thumbOffset(geometry: geometry), y: 0)
                        .gesture(dragGesture(geometry: geometry))
                }
                .frame(height: thumbSize) // Ensure consistent height for the slider track
                .sensoryFeedback(.selection, trigger: isDragSliderView)
                Spacer()
            }
            .frame(height: max(12, geometry.size.height))
        }
    }
    
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { gestureValue in
                let newValue = transformedValue(geometry: geometry, valueGesture: gestureValue)
                self.value = newValue
                isDragSliderView = true
            }
            .onEnded { _ in
                onCompletedDrag(value)
                isDragSliderView = false
            }
    }
    
    // Calculate progress width
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        guard maxValue > minValue else { return 0 }
        
        let normalizedValue = (value - minValue) / (maxValue - minValue)
        let availableWidth = geometry.size.width - thumbSize
        return max(0, availableWidth * CGFloat(normalizedValue))
    }
    
    // Calculate thumb offset
    private func thumbOffset(geometry: GeometryProxy) -> CGFloat {
        let progressW = progressWidth(geometry: geometry)
        return progressW
    }
    
    // Transform gesture location to slider value
    private func transformedValue(geometry: GeometryProxy, valueGesture: DragGesture.Value) -> Double {
        let availableWidth = geometry.size.width - thumbSize
        
        guard availableWidth > 0 else { return minValue }
        
        let adjustedX = valueGesture.location.x - (thumbSize / 2)
        let percent = Double(adjustedX / availableWidth)
        let clampedPercent = min(max(percent, 0), 1)
        
        return minValue + (clampedPercent * (maxValue - minValue))
    }
}

// MARK: - PREVIEW WRAPPER
struct PreviewWrapper: View {
    @State private var sliderValue: Double = 30
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Auto-sizing Slider Demo")
                .font(.title2)
                .bold()
            
            Text("Current Value: \(Int(sliderValue))")
                .font(.headline)
            
            Text("Is Dragging: \(isDragging ? "Yes" : "No")")
                .font(.subheadline)
                .foregroundColor(isDragging ? .red : .green)
            
            VStack(spacing: 20) {
                Text("Default size (no frame)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CustomSliderView(
                    value: $sliderValue,
                    isDragSliderView: $isDragging,
                    minValue: 0,
                    maxValue: 100,
                    trackColor: Color.gray.opacity(0.3),
                    progressColor: Color.blue
                ) { v in
                    print("Drag ended at: \(v)")
                }
                .padding(.horizontal, 20)
                
                Text("With 50pt height - centered")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CustomSliderView(
                    value: $sliderValue,
                    isDragSliderView: $isDragging,
                    minValue: 0,
                    maxValue: 100,
                    trackColor: Color.gray.opacity(0.3),
                    progressColor: Color.green
                ) { v in
                    print("Drag ended at: \(v)")
                }
                .frame(height: 50)
                .background(Color.gray.opacity(0.1))
                .padding(.horizontal, 20)
                
                Text("With 80pt height - centered")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                CustomSliderView(
                    value: $sliderValue,
                    isDragSliderView: $isDragging,
                    minValue: 0,
                    maxValue: 100,
                    trackColor: Color.gray.opacity(0.3),
                    progressColor: Color.red
                ) { v in
                    print("Drag ended at: \(v)")
                }
                .frame(height: 80)
                .background(Color.gray.opacity(0.1))
                .padding(.horizontal, 20)
            }
            
            // Test buttons
            HStack {
                Button("Set 25") {
                    sliderValue = 25
                }
                Button("Set 50") {
                    sliderValue = 50
                }
                Button("Set 75") {
                    sliderValue = 75
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - PREVIEW
struct CustomSliderView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
}
