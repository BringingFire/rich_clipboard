import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:markdown/markdown.dart' hide Text, Document;
import 'package:rich_clipboard/rich_clipboard.dart';
// ignore: implementation_imports
import 'package:super_editor/src/infrastructure/keyboard.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

class SuperEditorPage extends StatefulWidget {
  const SuperEditorPage({Key? key}) : super(key: key);

  @override
  State<SuperEditorPage> createState() => _SuperEditorPageState();
}

class _SuperEditorPageState extends State<SuperEditorPage> {
  late DocumentEditor _editor;

  @override
  void initState() {
    super.initState();
    final doc = deserializeMarkdownToDocument(starterDoc);
    _editor = DocumentEditor(document: doc);
  }

  @override
  void dispose() {
    _editor.document.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SuperEditor(
              editor: _editor,
              keyboardActions: [
                _copy,
                _paste,
                ...defaultKeyboardActions,
              ],
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  final oldDoc = _editor.document;
                  _editor = DocumentEditor(
                      document: deserializeMarkdownToDocument(starterDoc));
                  WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                    oldDoc.dispose();
                  });
                });
              },
              child: const Text('Reset'),
            ),
          )
        ],
      ),
    );
  }
}

ExecutionInstruction _copy(
    {required EditContext editContext, required RawKeyEvent keyEvent}) {
  if (!keyEvent.isPrimaryShortcutKeyPressed ||
      keyEvent.logicalKey != LogicalKeyboardKey.keyC) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || selection.isCollapsed) {
    return ExecutionInstruction.continueExecution;
  }

  final nodes = editContext.editor.document
      .getNodesInside(selection.base, selection.extent);

  final tmpDoc = MutableDocument(nodes: nodes);
  final markdown = serializeDocumentToMarkdown(tmpDoc);
  final html = markdownToHtml(markdown);

  RichClipboard.setData(RichClipboardData(
    text: markdown,
    html: html,
  ));

  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction _paste(
    {required EditContext editContext, required RawKeyEvent keyEvent}) {
  if (!keyEvent.isPrimaryShortcutKeyPressed ||
      keyEvent.logicalKey != LogicalKeyboardKey.keyV) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) {
    return ExecutionInstruction.continueExecution;
  }

  DocumentPosition pastePosition = selection.extent;

  // Delete all currently selected content.
  if (!selection.isCollapsed) {
    pastePosition =
        CommonEditorOperations.getDocumentPositionAfterExpandedDeletion(
      document: editContext.editor.document,
      selection: selection,
    );

    // Delete the selected content.
    editContext.editor.executeCommand(
      DeleteSelectionCommand(documentSelection: selection),
    );

    editContext.composer.selection =
        DocumentSelection.collapsed(position: pastePosition);
  }

  _pasteAsync(editContext.editor, editContext.composer, pastePosition);

  return ExecutionInstruction.haltExecution;
}

Future<void> _pasteAsync(DocumentEditor editor, DocumentComposer composer,
    DocumentPosition pastePosition) async {
  final data = await RichClipboard.getData();
  String markdown = '';
  if (data.html != null) {
    markdown = html2md.convert(data.html!);
  } else if (data.text != null) {
    markdown = data.text!;
  } else {
    return;
  }

  final doc = deserializeMarkdownToDocument(markdown);
  editor.executeCommand(_PasteEditorCommand(
    nodes: doc.nodes,
    composer: composer,
    pastePosition: pastePosition,
  ));
}

class _PasteEditorCommand implements EditorCommand {
  _PasteEditorCommand({
    required List<DocumentNode> nodes,
    required DocumentPosition pastePosition,
    required DocumentComposer composer,
  })  : _nodes = nodes,
        _pastePosition = pastePosition,
        _composer = composer;

  final List<DocumentNode> _nodes;
  final DocumentPosition _pastePosition;
  final DocumentComposer _composer;

  @override
  void execute(Document document, DocumentEditorTransaction transaction) {
    final currentNodeWithSelection =
        document.getNodeById(_pastePosition.nodeId);

    DocumentPosition? newSelectionPosition;

    if (currentNodeWithSelection is TextNode) {
      final pasteTextOffset =
          (_pastePosition.nodePosition as TextPosition).offset;

      if (currentNodeWithSelection is ParagraphNode) {
        SplitParagraphCommand(
          nodeId: currentNodeWithSelection.id,
          splitPosition: TextPosition(offset: pasteTextOffset),
          newNodeId: DocumentEditor.createNodeId(),
          replicateExistingMetadata: false,
        ).execute(document, transaction);
      } else {
        throw Exception(
            'Can\'t handle pasting text within node of type: $currentNodeWithSelection');
      }

      newSelectionPosition = DocumentPosition(
        nodeId: currentNodeWithSelection.id,
        nodePosition: TextNodePosition(
          offset: pasteTextOffset,
        ),
      );
    }

    int newNodeToMergeIndex = 0;
    DocumentNode mergeAfterNode;

    final nodeWithSelection = document.getNodeById(_pastePosition.nodeId);
    if (nodeWithSelection == null) {
      throw Exception(
          'Failed to complete paste process because the node being pasted into disappeared from the document unexpectedly.');
    }
    mergeAfterNode = nodeWithSelection;

    for (int i = newNodeToMergeIndex; i < _nodes.length; ++i) {
      transaction.insertNodeAfter(
        existingNode: mergeAfterNode,
        newNode: _nodes[i],
      );
      mergeAfterNode = _nodes[i];

      newSelectionPosition = DocumentPosition(
        nodeId: mergeAfterNode.id,
        nodePosition: mergeAfterNode.endPosition,
      );
    }

    _composer.selection = DocumentSelection.collapsed(
      position: newSelectionPosition!,
    );
    editorOpsLog.fine(' - new selection: ${_composer.selection}');

    editorOpsLog.fine('Done with paste command.');
  }
}

const starterDoc = '''
# Header 1

## Header 2

Paragraph with __*styled text*__

 * Unordered
   * list

 1. Ordered
 2. list
''';
