// ignore_for_file: public_member_api_docs, use_setters_to_change_properties, avoid_positional_boolean_parameters, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';

///Represents a node in a tree structure, which has references 
///to its _parent and _children (if any).
/// This is used to model a collapsing tree in the UI. 
/// It is possible to removeChild/add node onto the tree.

class TreeNode {
  TreeNode();

  final List<TreeNode> _children = [];
  List<TreeNode> _sortedList = [];
  TreeNode _parent = TreeNode();
  final bool _root = true;
  int _depth = 0;
  bool _expanded = true;
  bool _optionsExpanded = false;
  late BaseListItem _data;

  // Adds a child to the last index of this _parent node.
  //
  //@param child the child being added to this node
  //
  void addChild(TreeNode child) {
    if (!_children.contains(child)) {
      child.setParent(this);
      _children.add(child);
    }
  }

  // Adds a child to the first index of this _parent node.
  //
  // @param child the child being added to this node
  //
  void addChildAsFirstElement(TreeNode child) {
    if (!_children.contains(child)) {
      child.setParent(this);
      _children.insert(0, child);
    }
  }

  // Removes a child from the _parent node.
  //
  //@param child the child being removed from this node

  void removeChild(TreeNode child) {
    _children.remove(child);
    // child.set_Parent(null);
  }

  List<TreeNode> getChildren() {
    return _children;
  }

  TreeNode getParent() {
    return _parent;
  }

  void setParent(TreeNode parent) {
    _parent = parent;
  }

  bool isRoot() {
    return _root;
  }

  bool hasChildren() {
    return _children.isNotEmpty;
  }

  int getDepth() {
    return _depth;
  }

  void setDepth(int depth) {
    _depth = depth;
  }

  BaseListItem getData() {
    return _data;
  }

  void setData(BaseListItem data) {
    _data = data;
  }

  bool isExpanded() {
    return _expanded;
  }

  void setExpanded(bool expanded) {
    _expanded = expanded;
  }

  // Recurse to give an ordered comment tree list.
  //Node _children must be in an expanded state
  //to be added to this list.
  //
  // @return an ordered comment tree list
  //
  List<TreeNode> toList() {
    final orderedList = <TreeNode>[];

    for (final child in _children) {
      if (_expanded) {
        orderedList
          ..add(child)
          ..addAll(child.toList());
      }
    }
    return orderedList;
  }

  int size() {
    return _sortedList.length;
  }

  void notifyDataChanged() {
    _sortedList = toList();
  }

  TreeNode getNodeAtIndex(int index) {
    return _sortedList.elementAt(index);
  }

  // Finds the comment by its id, if any exists
  //
  // @param id the comment id
  // @return the matching comment, or null

  TreeNode? getNodeById(String id) {
    for (final node in _sortedList) {
      if (id == (node.getData().id)) {
        return node;
      }
    }
    return null;
  }

  // Finds the index of the child node
  //
  // @param child the given child
  // @return the index of the child in this list, or -1

  int getNodeIndex(TreeNode child) {
    for (var i = 0; i < size(); i++) {
      final node = _sortedList.elementAt(i);

      if (node == child) {
        return i;
      }
    }
    return -1;
  }

  bool isOptionsExpanded() {
    return _optionsExpanded;
  }

  void setOptionsExpanded(bool optionsExpanded) {
    _optionsExpanded = optionsExpanded;
  }
}
