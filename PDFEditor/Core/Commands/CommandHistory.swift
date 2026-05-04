import Foundation

final class CommandHistory: ObservableObject {
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var undoStack: [Command] = []
    private var redoStack: [Command] = []

    func execute(_ command: Command) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        updateState()
    }

    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        updateState()
    }

    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.execute()
        undoStack.append(command)
        updateState()
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }

    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
