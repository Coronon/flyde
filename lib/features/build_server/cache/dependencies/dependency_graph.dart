import 'package:json_annotation/json_annotation.dart';

part 'dependency_graph.g.dart';

/// A data structure connecting multiple nodes with each other.
///
/// The nodes are the different source files and the connnections
/// are the deppendencies bewteen them.
///
/// [DependencyGraph] is serializable and can therefore be persisted.
/// `nodes` should not be accessed directly, but rather through the
/// `add`, `remove` and `update` methods.
///
/// To set up the connections between the nodes, `connect` should be
/// used. Information about dependencies can then be retrieved through
/// the dedicated getters.
@JsonSerializable()
class DependencyGraph {
  /// The set of available nodes.
  ///
  /// Each represents a source file.
  /// Do not access from outside the class.
  final Set<_DependencyNode> nodes;

  DependencyGraph({required this.nodes});

  /// Creatrs a new graph from a set of available ids.
  DependencyGraph.fromIds(Set<String> availableIds) : nodes = _convert(availableIds);

  factory DependencyGraph.fromJson(Map<String, dynamic> json) => _$DependencyGraphFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyGraphToJson(this);

  /// Adds a new node to the graph with the given id.
  void add(String nodeId) {
    nodes.addAll(_convert({nodeId}));
  }

  /// Removes the node with the given id from the graph.
  void remove(String nodeId) {
    nodes.removeWhere((node) => node.id == nodeId);
  }

  /// Updates the graph structure.
  ///
  /// Nodes with an id not in [availableIds] are removed
  /// while all other nodes are added if not already present.
  /// Possible connections to newly deleted nodes are removed as well.
  void update(Set<String> availableIds) {
    final toBeRemoved = nodes.where((node) => !availableIds.contains(node.id)).toSet();

    nodes.addAll(_convert(availableIds));
    nodes.removeAll(toBeRemoved);

    for (final node in nodes) {
      node.dependencies.removeAll(toBeRemoved.map((node) => node.id));
      node.dependents.removeAll(toBeRemoved.map((node) => node.id));
    }
  }

  /// Connects the node with the id [source] with it's [dependencies]
  void connect(String source, Set<String> dependencies) {
    final srcNode = _getNode(source);

    for (final node in nodes) {
      // add dependencies to source node
      if (node == srcNode) {
        node.dependencies = dependencies.toSet();
        continue;
      }

      // add source node to it's dependencies or remove if no longer included
      if (dependencies.contains(node.id)) {
        node.dependents.add(srcNode.id);
      } else {
        node.dependents.remove(srcNode.id);
      }
    }
  }

  /// Returns a set of all nodes that depend on the node with the id [file].
  Set<String> dependents(String file) => _getNode(file).dependents.toSet();

  /// Returns a set of all nodes that depend even indirectly on the node with the id [file].
  ///
  /// Unlike `dependents`, also node ids are returned which are not directly dependent on [file].
  /// If [file] is dependent on node `a` and node `a` is dependent on node `b`,
  /// node `a` is returned as well as node `b`.
  Set<String> indirectDependents(String file) {
    final result = <String>{};

    void addDepentents(_DependencyNode node) {
      for (final dependent in node.dependents.map((e) => _getNode(e))) {
        if (!result.contains(dependent.id)) {
          result.add(dependent.id);
          addDepentents(dependent);
        }
      }
    }

    addDepentents(_getNode(file));

    return result;
  }

  /// Returns a set of all nodes that [file] depends on.
  Set<String> dependencies(String file) => _getNode(file).dependencies.toSet();

  /// Returns a set of all nodes that [file] depends on even indirectly.
  ///
  /// If [file] depents on node `a` and node `a` is dependent on node `b`,
  /// node `a` is returned as well as node `b`.
  Set<String> indirectDependencies(String file) {
    final result = <String>{};

    void addDependencies(_DependencyNode node) {
      for (final dependency in node.dependencies.map((e) => _getNode(e))) {
        if (!result.contains(dependency.id)) {
          result.add(dependency.id);
          addDependencies(dependency);
        }
      }
    }

    addDependencies(_getNode(file));

    return result;
  }

  /// Finds the node with the given [id] and returns it.
  ///
  /// If no node with the given id exists, an error is thrown.
  _DependencyNode _getNode(String id) => nodes.singleWhere((node) => node.id == id);

  /// Converts a set of ids to a set of nodes without any dependencies.
  static Set<_DependencyNode> _convert(Set<String> ids) =>
      ids.map((id) => _DependencyNode(id: id, dependencies: {}, dependents: {})).toSet();
}

/// A single node representing a source file with
/// different dependencies and dependents.
@JsonSerializable()
class _DependencyNode {
  /// The id of the node.
  ///
  /// Sole parameter for equality checks.
  final String id;

  /// The set of dependencies of the node.
  Set<String> dependencies;

  /// The set of dependents of the node.
  Set<String> dependents;

  _DependencyNode({
    required this.id,
    required this.dependencies,
    required this.dependents,
  });

  factory _DependencyNode.fromJson(Map<String, dynamic> json) => _$DependencyNodeFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyNodeToJson(this);

  //? Implement hashCode and equality operator for usage in `Set`s

  @override
  bool operator ==(Object other) => other is _DependencyNode ? other.id == id : false;

  @override
  int get hashCode => id.hashCode;
}
