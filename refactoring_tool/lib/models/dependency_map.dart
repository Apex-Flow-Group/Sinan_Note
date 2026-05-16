/// يمثل عقدة في خريطة التبعيات
class DependencyNode {
  final String functionName;
  final String filePath;
  final int depth;
  final List<DependencyNode> children;

  const DependencyNode({
    required this.functionName,
    required this.filePath,
    required this.depth,
    this.children = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'filePath': filePath,
      'depth': depth,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  factory DependencyNode.fromJson(Map<String, dynamic> json) {
    return DependencyNode(
      functionName: json['functionName'] as String,
      filePath: json['filePath'] as String,
      depth: json['depth'] as int,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => DependencyNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'DependencyNode($functionName at $filePath, depth: $depth)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyNode &&
          runtimeType == other.runtimeType &&
          functionName == other.functionName &&
          filePath == other.filePath &&
          depth == other.depth;

  @override
  int get hashCode => Object.hash(functionName, filePath, depth);
}

/// خريطة التبعيات حتى 3 مستويات
class DependencyMap {
  final String rootFunction;
  final List<DependencyNode> upstreamCallers;
  final List<DependencyNode> downstreamCallees;
  final bool hasCircularChain;
  final List<String> circularParticipants;

  const DependencyMap({
    required this.rootFunction,
    this.upstreamCallers = const [],
    this.downstreamCallees = const [],
    this.hasCircularChain = false,
    this.circularParticipants = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'rootFunction': rootFunction,
      'upstreamCallers': upstreamCallers.map((n) => n.toJson()).toList(),
      'downstreamCallees': downstreamCallees.map((n) => n.toJson()).toList(),
      'hasCircularChain': hasCircularChain,
      'circularParticipants': circularParticipants,
    };
  }

  factory DependencyMap.fromJson(Map<String, dynamic> json) {
    return DependencyMap(
      rootFunction: json['rootFunction'] as String,
      upstreamCallers: (json['upstreamCallers'] as List<dynamic>?)
              ?.map((e) => DependencyNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      downstreamCallees: (json['downstreamCallees'] as List<dynamic>?)
              ?.map((e) => DependencyNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasCircularChain: json['hasCircularChain'] as bool? ?? false,
      circularParticipants: (json['circularParticipants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'DependencyMap($rootFunction: ${upstreamCallers.length} upstream, ${downstreamCallees.length} downstream, circular: $hasCircularChain)';
}
