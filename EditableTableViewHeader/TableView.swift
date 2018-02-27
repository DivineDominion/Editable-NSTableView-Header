//
//  TableView.swift
//  EditableTableViewHeader
//
//  Created by Christian Tietze on 11/04/16.
//  Copyright © 2016 Christian Tietze. All rights reserved.
//

import Cocoa

class TableWindowController: NSWindowController {

    static let nibName = "TableWindow"

    @IBOutlet var tableView: NSTableView!

    override func awakeFromNib() {

        super.awakeFromNib()

        for tableColumn in self.tableView.tableColumns {

            let content = tableColumn.title
            let headerCell = TableHeaderCell()
            headerCell.isEditable = true
            headerCell.usesSingleLineMode = true
            headerCell.isScrollable = false
            headerCell.lineBreakMode = .byTruncatingTail
            tableColumn.headerCell = headerCell
            tableColumn.title = content
        }
    }

    lazy var headerFieldEditor: HeaderFieldEditor = {

        let editor = HeaderFieldEditor()
        editor.isFieldEditor = true
        return editor
    }()
}


// MARK: Field editor usage

class HeaderFieldEditor: NSTextView {

    func switchEditingTarget() {

        guard let cell = self.delegate as? NSCell else { return }

        cell.endEditing(self)
    }
}

extension TableWindowController: NSWindowDelegate {

    /// Convenience accessor to the `window`s field editor.
    func fieldEditor(object: AnyObject?) -> NSText? {

        return self.window?.fieldEditor(true, for: object)
    }

    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        
        // Return default field editor for everything not in the header.
        guard client is TableHeaderView else { return nil }

        // Comment out this line to see what happens by default: the old header
        // is not deselected.
        headerFieldEditor.switchEditingTarget()

        return headerFieldEditor
    }
}

// MARK: Header view and header view cell 

class TableHeaderView: NSTableHeaderView {

    /// Trial and error result of the text frame that fits.
    struct Padding {
        static let Vertical: CGFloat = 4
        static let Right: CGFloat = 1
    }

    /// By default, the field editor will be very high and thus look weird.
    /// This scales the header rect down a bit so the field editor is put
    /// truly in place.
    func paddedHeaderRect(column: Int) -> NSRect {

        let paddedVertical = self.headerRect(ofColumn: column).insetBy(dx: 0, dy: Padding.Vertical)
        let paddedRight = CGRect(
            origin: paddedVertical.origin,
            size: CGSize(width: paddedVertical.width - Padding.Right, height: paddedVertical.height))

        return paddedRight
    }
}

class TableHeaderCell: NSTableHeaderCell, NSTextViewDelegate {

    func edit(fieldEditor: NSText, frame: NSRect, headerView: NSView) {

        let endOfText = (self.stringValue as NSString).length
        self.isHighlighted = true
        self.select(withFrame: frame,
                           in: headerView,
                       editor: fieldEditor,
                     delegate: self,
                        start: endOfText,
                       length: 0)

        fieldEditor.backgroundColor = .white
        fieldEditor.drawsBackground = true
    }

    func textDidEndEditing(_ notification: Notification) {

        guard let editor = notification.object as? NSText else { return }

        self.title = editor.string
        print("Header did change to \(self.title)")
        self.isHighlighted = false

        // The following will fire a regular `NSTextDidEndEditingNotification`:
        self.endEditing(editor)
    }
}


// MARK: Table interaction: double click

extension Collection where Index : Comparable {

    subscript (safe index: Index) -> Element? {
        return index < endIndex ? self[index] : nil
    }
}

extension NSTableView {

    func tableColumn(column index: Int) -> NSTableColumn? {
        return tableColumns[safe: index]
    }
}

extension TableWindowController {

    @IBAction func tableViewDoubleClick(_ sender: NSTableView) {

        let column = sender.clickedColumn
        let row = sender.clickedRow

        guard column > -1 else { return }

        if row == -1 {
            editColumnHeader(tableView: sender, column: column)
            return
        }

        editCell(tableView: sender, column: column, row: row)
    }

    private func editColumnHeader(tableView: NSTableView, column: Int) {

        guard column > -1,
            let tableColumn = tableView.tableColumn(column: column),
            let headerView = tableView.headerView as? TableHeaderView,
            let headerCell = tableColumn.headerCell as? TableHeaderCell,
            let fieldEditor = fieldEditor(object: headerView)
            else { return }

        headerCell.edit(
            fieldEditor: fieldEditor,
            frame: headerView.paddedHeaderRect(column: column),
            headerView: headerView)
    }

    private func editCell(tableView: NSTableView, column: Int, row: Int) {

        guard row > -1 && column > -1,
            let view = tableView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView
            else { return }

        view.textField?.selectText(self)
    }
}

