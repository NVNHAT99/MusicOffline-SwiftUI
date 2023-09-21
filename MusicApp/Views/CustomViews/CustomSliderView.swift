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
    var trackHeight: CGFloat
    var minValue: Double
    var maxValue: Double
    var trackColor: Color
    var progressColor: Color
    let onCompletedDrag: (Double) -> Void
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor)
                    .frame(height: trackHeight)
                
                // Progress
                Capsule()
                    .fill(progressColor)
                    .frame(width: progressWidth(geometry: geometry), height: trackHeight)
                
                // Thumb
                Circle()
                    .fill(progressColor)
                    .frame(width: geometry.size.height, height: geometry.size.height)
                    .offset(x: thumbOffset(geometry: geometry), y: 0)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                self.value = transformedValue(geometry: geometry, valueGesture: value) * maxValue
                                isDragSliderView = true
                            }
                            .onEnded({ _ in
                                onCompletedDrag(value)
                                isDragSliderView = false
                            })
                    )
            }
        }
    }
    
    // Calculate progress width
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        let fullWidth = geometry.size.width
        return fullWidth * CGFloat(self.value / maxValue)
    }
    
    // Calculate thumb offset
    private func thumbOffset(geometry: GeometryProxy) -> CGFloat {
        if progressWidth(geometry: geometry) - (trackHeight) < 0 {
            return 0
        }
        return progressWidth(geometry: geometry) - (trackHeight)
    }
    
    // Transform gesture location to slider value
    private func transformedValue(geometry: GeometryProxy, valueGesture: DragGesture.Value) -> Double {
        let width = geometry.size.width
        let percent = Double(valueGesture.location.x / width)
        return Double(min(max(percent, 0), 1))
    }
}

