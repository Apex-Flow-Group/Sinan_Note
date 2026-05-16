import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/dependency_map.dart';

/// نتيجة حل الاستدعاءات لدالة معينة
class ResolvedCalls {
  /// الدوال التي تستدعي هذه الدالة (upstream callers)
  final List<CallSource> callers;

  /// الدوال التي تستدعيها هذه الدالة (downstream callees)
  final List<CallSource> callees;

  const ResolvedCalls({
    this.callers = const [],
    this.callees = const [],
  });
}

/// دالة حل الاستدعاءات: تأخذ اسم دالة وتعيد مصادر الاستدعاء
typedef CallResolver = ResolvedCalls Function(String functionName);

/// أداة بناء خريطة التبعيات حتى 3 مستويات
/// تكشف السلاسل الدائرية بين الدوال
class DependencyGrapher {
  final CallResolver _resolver;

  /// الحد الأقصى لعمق البحث
  static const int maxDepth = 3;

  DependencyGrapher(this._resolver);

  /// بناء خريطة التبعيات لدالة معينة
  ///
  /// [rootFunction] اسم الدالة الجذرية
  /// [rootFilePath] مسار ملف الدالة الجذرية (اختياري، يُستخدم للعرض)
  DependencyMap buildDependencyMap(String rootFunction,
      {String rootFilePath = ''}) {
    // بناء الشجرة في الاتجاهين
    final visited = <String>{};
    final upstreamCallers = _buildUpstream(rootFunction, 1, visited);

    visited.clear();
    final downstreamCallees = _buildDownstream(rootFunction, 1, visited);

    // كشف السلاسل الدائرية
    final upstreamNames = _collectAllFunctionNames(upstreamCallers);
    final downstreamNames = _collectAllFunctionNames(downstreamCallees);

    // دالة تظهر في كلا الاتجاهين = سلسلة دائرية
    final circularParticipants =
        upstreamNames.intersection(downstreamNames).toList()..sort();

    final hasCircularChain = circularParticipants.isNotEmpty;

    return DependencyMap(
      rootFunction: rootFunction,
      upstreamCallers: upstreamCallers,
      downstreamCallees: downstreamCallees,
      hasCircularChain: hasCircularChain,
      circularParticipants: circularParticipants,
    );
  }

  /// بناء شجرة المستدعين (upstream) بشكل تكراري حتى العمق المحدد
  List<DependencyNode> _buildUpstream(
      String functionName, int currentDepth, Set<String> visited) {
    if (currentDepth > maxDepth) return [];
    if (visited.contains(functionName)) return [];

    visited.add(functionName);

    final resolved = _resolver(functionName);
    final nodes = <DependencyNode>[];

    for (final caller in resolved.callers) {
      if (caller.callingFunction == functionName) continue;

      final children = _buildUpstream(
          caller.callingFunction, currentDepth + 1, Set<String>.from(visited));

      nodes.add(DependencyNode(
        functionName: caller.callingFunction,
        filePath: caller.filePath,
        depth: currentDepth,
        children: children,
      ));
    }

    return nodes;
  }

  /// بناء شجرة المستدعَيات (downstream) بشكل تكراري حتى العمق المحدد
  List<DependencyNode> _buildDownstream(
      String functionName, int currentDepth, Set<String> visited) {
    if (currentDepth > maxDepth) return [];
    if (visited.contains(functionName)) return [];

    visited.add(functionName);

    final resolved = _resolver(functionName);
    final nodes = <DependencyNode>[];

    for (final callee in resolved.callees) {
      if (callee.callingFunction == functionName) continue;

      final children = _buildDownstream(
          callee.callingFunction, currentDepth + 1, Set<String>.from(visited));

      nodes.add(DependencyNode(
        functionName: callee.callingFunction,
        filePath: callee.filePath,
        depth: currentDepth,
        children: children,
      ));
    }

    return nodes;
  }

  /// جمع جميع أسماء الدوال من شجرة العقد
  Set<String> _collectAllFunctionNames(List<DependencyNode> nodes) {
    final names = <String>{};
    for (final node in nodes) {
      names.add(node.functionName);
      names.addAll(_collectAllFunctionNames(node.children));
    }
    return names;
  }
}
