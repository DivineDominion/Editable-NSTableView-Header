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
            headerCell.editable = true
            headerCell.usesSingleLineMode = true
            headerCell.scrollable = false
            headerCell.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            tableColumn.headerCell = headerCell
            tableColumn.title = content
        }
    }

    lazy var headerFieldEditor: HeaderFieldEditor = {

        let editor = HeaderFieldEditor()
        editor.fieldEditor = true
        return editor
    }()
}


// MARK: Field editor usage

class HeaderFieldEditor: NSTextView {

    static let ManualEndEditing = "field editor will change"

    func switchEditingTarget() {

        guard let delegate = self.delegate else { return }

        let notification = NSNotification(name: HeaderFieldEditor.ManualEndEditing, object: self)
        delegate.textDidEndEditing?(notification)
    }
}

extension TableWindowController: NSWindowDelegate {

    /// Convenience accessor to the `window`s field editor.
    func fieldEditor(object object: AnyObject?) -> NSText? {

        return self.window?.fieldEditor(true, forObject: object)
    }

    func windowWillReturnFieldEditor(sender: NSWindow, toObject client: AnyObject?) -> AnyObject? {

        // Return default field editor for everything not in the header.
        guard client is TableHeaderView else { return nil }

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
    func paddedHeaderRect(column column: Int) -> NSRect {

        let paddedVertical = CGRectInset(self.headerRectOfColumn(column), 0, Padding.Vertical)
        let paddedRight = CGRect(
            origin: paddedVertical.origin,
            size: CGSize(width: paddedVertical.width - Padding.Right, height: paddedVertical.height))

        return paddedRight
    }
}

class TableHeaderCell: NSTableHeaderCell, NSTextViewDelegate {

    func edit(fieldEditor fieldEditor: NSText, frame: NSRect, headerView: NSView) {

        let endOfText = (self.stringValue as NSString).length
        self.highlighted = true
        self.selectWithFrame(frame,
            inView: headerView,
            editor: fieldEditor,
            delegate: self,
            start: endOfText,
            length: 0)

        fieldEditor.backgroundColor = NSColor.whiteColor()
        fieldEditor.drawsBackground = true
    }

    func textDidEndEditing(notification: NSNotification) {

        guard let editor = notification.object as? NSText else { return }

        self.title = editor.string ?? ""
        self.highlighted = false
        self.endEditing(editor)
    }
}


// MARK: Table interaction: double click

extension CollectionType where Self.Index : Comparable {

    subscript (safe index: Self.Index) -> Self.Generator.Element? {
        return index < endIndex ? self[index] : nil
    }
}

extension NSTableView {

    func tableColumn(column index: Int) -> NSTableColumn? {
        return tableColumns[safe: index]
    }
}

extension TableWindowController {

    @IBAction func tableViewDoubleClick(sender: NSTableView) {

        let column = sender.clickedColumn
        let row = sender.clickedRow

        guard column > -1 else { return }

        if row == -1 {
            editColumnHeader(tableView: sender, column: column)
            return
        }

        editCell(tableView: sender, column: column, row: row)
    }

    private func editColumnHeader(tableView tableView: NSTableView, column: Int) {

        guard column > -1,
            let tableColumn = tableView.tableColumn(column: column),
            headerView = tableView.headerView as? TableHeaderView,
            headerCell = tableColumn.headerCell as? TableHeaderCell,
            fieldEditor = fieldEditor(object: headerView)
            else { return }

        headerCell.edit(
            fieldEditor: fieldEditor,
            frame: headerView.paddedHeaderRect(column: column),
            headerView: headerView)
    }

    private func editCell(tableView tableView: NSTableView, column: Int, row: Int) {

        guard row > -1 && column > -1,
            let view = tableView.viewAtColumn(column, row: row, makeIfNecessary: true) as? NSTableCellView
            else { return }

        view.textField?.selectText(self)
    }
}

