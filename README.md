# PDF Editor

An iOS app for importing, editing, and exporting PDF files.

## Features (MVP)
- Import PDFs from Files app / iCloud Drive
- View and reorder pages with thumbnails
- Rotate and delete pages
- Merge multiple PDFs
- Split a PDF by page range
- Export via share sheet

## Requirements
- iOS 16+
- Xcode 16+

## Architecture
MVVM + lightweight Coordinator pattern. PDF operations run on a Swift `actor` to ensure thread safety with PDFKit.

```
App/           — entry point, coordinator, environment container
Features/      — one folder per screen/flow
Core/PDF/      — PDFProcessingActor, DocumentManager, PDFPageModel
Core/Commands/ — Command protocol + CommandHistory (undo/redo)
UI/            — reusable components and theme
```

## Milestones
| Milestone | Goal |
|-----------|------|
| v0.1 | Project setup, CI green |
| v0.2 | Import & thumbnail grid |
| v0.3 | Page operations (reorder, delete, rotate) + undo/redo |
| v0.4 | Merge & split |
| v0.5 | Export & share |
| v1.0 | MVP release / TestFlight |
