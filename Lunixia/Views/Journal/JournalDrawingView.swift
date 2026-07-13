//
//  JournalDrawingView.swift
//  Lunixia
//

import SwiftUI
import PencilKit

struct JournalDrawingView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var drawingData: Data

    @State private var canvasView = PKCanvasView()
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            JournalCanvasRepresentable(
                canvasView: $canvasView,
                drawingData: $drawingData
            )
            .background(Color.black)
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        canvasView.undoManager?.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }

                    Button {
                        canvasView.undoManager?.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)

                    Button("Save") {
                        drawingData = canvasView.drawing.dataRepresentation()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Delete Drawing?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    canvasView.drawing = PKDrawing()
                    drawingData = Data()
                    dismiss()
                }
            } message: {
                Text("This will permanently remove this drawing.")
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct JournalCanvasRepresentable: UIViewRepresentable {

    @Binding var canvasView: PKCanvasView
    @Binding var drawingData: Data

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let toolPicker = PKToolPicker()
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput

        if let drawing = try? PKDrawing(data: drawingData) {
            canvasView.drawing = drawing
        }

        let picker = context.coordinator.toolPicker
        picker.setVisible(true, forFirstResponder: canvasView)
        picker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let drawing = try? PKDrawing(data: drawingData),
           uiView.drawing.dataRepresentation() != drawingData {
            uiView.drawing = drawing
        }
    }
}
