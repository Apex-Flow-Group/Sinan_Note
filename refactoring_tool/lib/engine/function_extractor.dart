import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:refactoring_tool/models/function_unit.dart';

/// Result of function extraction from a file.
class ExtractionResult {
  final List<FunctionUnit> functions;
  final String? notification;

  const ExtractionResult({
    required this.functions,
    this.notification,
  });
}

/// Extracts all analyzable functions from a Dart file using AST parsing.
///
/// Extracts: class methods, constructors, top-level functions, build methods,
/// getters/setters.
/// Excludes: anonymous closures (FunctionExpression without name), inline
/// lambda expressions.
class FunctionExtractor {
  /// Extracts all [FunctionUnit] entries from the file at [filePath].
  ///
  /// Returns an [ExtractionResult] containing the sorted list of functions
  /// and an optional notification message if no functions were found.
  ExtractionResult extractFromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return ExtractionResult(
        functions: [],
        notification: 'File not found: $filePath',
      );
    }

    final source = file.readAsStringSync();
    return extractFromSource(source, filePath);
  }

  /// Extracts all [FunctionUnit] entries from the given [source] string.
  ///
  /// [filePath] is used for metadata in the returned [FunctionUnit] entries.
  ExtractionResult extractFromSource(String source, String filePath) {
    final parseResult = parseString(content: source);
    final unit = parseResult.unit;

    final visitor = _FunctionVisitor(source, filePath);
    unit.visitChildren(visitor);

    final functions = visitor.functions;

    // Sort by startLine ascending (declaration order)
    functions.sort((a, b) => a.startLine.compareTo(b.startLine));

    if (functions.isEmpty) {
      return ExtractionResult(
        functions: [],
        notification: 'No extractable functions found in: $filePath',
      );
    }

    return ExtractionResult(functions: functions);
  }
}

/// AST visitor that collects function declarations from a Dart file.
class _FunctionVisitor extends RecursiveAstVisitor<void> {
  final String source;
  final String filePath;
  final List<FunctionUnit> functions = [];

  _FunctionVisitor(this.source, this.filePath);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final functionType = _determineFunctionType(node);
    final name = node.name.lexeme;
    final startLine = _getStartLine(node);
    final endLine = _getEndLine(node);
    final lineCount = endLine - startLine + 1;
    final params = _extractMethodParameters(node);
    final returnType = _extractReturnType(node.returnType);
    final body = _extractNodeText(node);
    final signature = _buildMethodSignature(node);
    final annotations = _extractAnnotations(node.metadata);
    final docComment = _extractDocComment(node.documentationComment);

    functions.add(FunctionUnit(
      name: name,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      lineCount: lineCount,
      signature: signature,
      returnType: returnType,
      params: params,
      body: _buildFullBody(annotations, docComment, body),
      type: functionType,
    ));

    // Do not recurse into method bodies to avoid picking up nested lambdas
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    final startLine = _getStartLine(node);
    final endLine = _getEndLine(node);
    final lineCount = endLine - startLine + 1;
    final params = _extractFunctionParameters(node.functionExpression);
    final returnType = _extractReturnType(node.returnType);
    final body = _extractNodeText(node);
    final signature = _buildFunctionSignature(node);
    final annotations = _extractAnnotations(node.metadata);
    final docComment = _extractDocComment(node.documentationComment);

    functions.add(FunctionUnit(
      name: name,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      lineCount: lineCount,
      signature: signature,
      returnType: returnType,
      params: params,
      body: _buildFullBody(annotations, docComment, body),
      type: FunctionType.topLevel,
    ));

    // Do not recurse into function bodies
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final className = (node.parent as ClassDeclaration?)?.name.lexeme ?? '';
    final constructorName = node.name?.lexeme;
    final name =
        constructorName != null ? '$className.$constructorName' : className;
    final startLine = _getStartLine(node);
    final endLine = _getEndLine(node);
    final lineCount = endLine - startLine + 1;
    final params = _extractConstructorParameters(node);
    final returnType = className;
    final body = _extractNodeText(node);
    final signature = _buildConstructorSignature(node, className);
    final annotations = _extractAnnotations(node.metadata);
    final docComment = _extractDocComment(node.documentationComment);

    functions.add(FunctionUnit(
      name: name,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      lineCount: lineCount,
      signature: signature,
      returnType: returnType,
      params: params,
      body: _buildFullBody(annotations, docComment, body),
      type: FunctionType.constructor,
    ));

    // Do not recurse into constructor bodies
  }

  // --- Helper methods ---

  FunctionType _determineFunctionType(MethodDeclaration node) {
    if (node.isGetter) return FunctionType.getter;
    if (node.isSetter) return FunctionType.setter;

    final name = node.name.lexeme;
    if (name == 'build') {
      // Check if the parent class extends StatelessWidget or State
      final parent = node.parent;
      if (parent is ClassDeclaration) {
        final extendsClause = parent.extendsClause;
        if (extendsClause != null) {
          final superName = extendsClause.superclass.name2.lexeme;
          if (superName == 'StatelessWidget' || superName.startsWith('State')) {
            return FunctionType.buildMethod;
          }
        }
      }
      // Even without extends check, a method named 'build' with
      // BuildContext parameter is likely a build method
      final params = node.parameters?.parameters ?? [];
      for (final param in params) {
        if (param is SimpleFormalParameter) {
          final typeStr = param.type?.toSource() ?? '';
          if (typeStr == 'BuildContext') {
            return FunctionType.buildMethod;
          }
        }
      }
    }

    return FunctionType.method;
  }

  int _getStartLine(AstNode node) {
    // Account for annotations and doc comments
    final annotatedNode = node;
    int offset;
    if (annotatedNode is AnnotatedNode && annotatedNode.metadata.isNotEmpty) {
      offset = annotatedNode.metadata.first.offset;
    } else if (annotatedNode is AnnotatedNode &&
        annotatedNode.documentationComment != null) {
      offset = annotatedNode.documentationComment!.offset;
    } else {
      offset = node.offset;
    }
    return _lineNumberAt(offset);
  }

  int _getEndLine(AstNode node) {
    return _lineNumberAt(node.end - 1);
  }

  int _lineNumberAt(int offset) {
    int line = 1;
    for (int i = 0; i < offset && i < source.length; i++) {
      if (source[i] == '\n') line++;
    }
    return line;
  }

  List<Parameter> _extractMethodParameters(MethodDeclaration node) {
    final paramList = node.parameters;
    if (paramList == null) return [];
    return _extractParameterList(paramList);
  }

  List<Parameter> _extractFunctionParameters(FunctionExpression expr) {
    final paramList = expr.parameters;
    if (paramList == null) return [];
    return _extractParameterList(paramList);
  }

  List<Parameter> _extractConstructorParameters(ConstructorDeclaration node) {
    final paramList = node.parameters;
    return _extractParameterList(paramList);
  }

  List<Parameter> _extractParameterList(FormalParameterList paramList) {
    final result = <Parameter>[];
    for (final param in paramList.parameters) {
      final extracted = _extractSingleParameter(param);
      if (extracted != null) {
        result.add(extracted);
      }
    }
    return result;
  }

  Parameter? _extractSingleParameter(FormalParameter param) {
    String name;
    String type;
    bool isRequired;
    bool isNamed;
    String? defaultValue;

    if (param is DefaultFormalParameter) {
      isNamed = param.isNamed;
      defaultValue = param.defaultValue?.toSource();
      final innerParam = param.parameter;
      final extracted = _extractBaseParameter(innerParam);
      if (extracted == null) return null;
      name = extracted.name;
      type = extracted.type;
      // Check if explicitly marked required
      isRequired = innerParam is SimpleFormalParameter &&
              innerParam.requiredKeyword != null ||
          !isNamed;
    } else {
      isNamed = param.isNamed;
      final extracted = _extractBaseParameter(param);
      if (extracted == null) return null;
      name = extracted.name;
      type = extracted.type;
      isRequired = !isNamed;
      defaultValue = null;
    }

    return Parameter(
      name: name,
      type: type,
      isRequired: isRequired,
      isNamed: isNamed,
      defaultValue: defaultValue,
    );
  }

  ({String name, String type})? _extractBaseParameter(FormalParameter param) {
    if (param is SimpleFormalParameter) {
      final name = param.name?.lexeme ?? '';
      final type = param.type?.toSource() ?? 'dynamic';
      return (name: name, type: type);
    } else if (param is FieldFormalParameter) {
      final name = param.name.lexeme;
      final type = param.type?.toSource() ?? 'dynamic';
      return (name: name, type: type);
    } else if (param is SuperFormalParameter) {
      final name = param.name.lexeme;
      final type = param.type?.toSource() ?? 'dynamic';
      return (name: name, type: type);
    } else if (param is FunctionTypedFormalParameter) {
      final name = param.name.lexeme;
      final returnType = param.returnType?.toSource() ?? 'void';
      final params = param.parameters.toSource();
      final type = '$returnType Function$params';
      return (name: name, type: type);
    }
    return null;
  }

  String _extractReturnType(TypeAnnotation? typeAnnotation) {
    if (typeAnnotation == null) return 'void';
    return typeAnnotation.toSource();
  }

  String _extractNodeText(AstNode node) {
    return source.substring(node.offset, node.end);
  }

  String _buildMethodSignature(MethodDeclaration node) {
    final buffer = StringBuffer();
    if (node.isStatic) buffer.write('static ');
    if (node.returnType != null) {
      buffer.write('${node.returnType!.toSource()} ');
    }
    if (node.isGetter) {
      buffer.write('get ${node.name.lexeme}');
    } else if (node.isSetter) {
      buffer.write('set ${node.name.lexeme}');
      if (node.parameters != null) {
        buffer.write(node.parameters!.toSource());
      }
    } else {
      buffer.write(node.name.lexeme);
      if (node.typeParameters != null) {
        buffer.write(node.typeParameters!.toSource());
      }
      if (node.parameters != null) {
        buffer.write(node.parameters!.toSource());
      }
    }
    return buffer.toString();
  }

  String _buildFunctionSignature(FunctionDeclaration node) {
    final buffer = StringBuffer();
    if (node.returnType != null) {
      buffer.write('${node.returnType!.toSource()} ');
    }
    buffer.write(node.name.lexeme);
    final expr = node.functionExpression;
    if (expr.typeParameters != null) {
      buffer.write(expr.typeParameters!.toSource());
    }
    if (expr.parameters != null) {
      buffer.write(expr.parameters!.toSource());
    }
    return buffer.toString();
  }

  String _buildConstructorSignature(
      ConstructorDeclaration node, String className) {
    final buffer = StringBuffer();
    if (node.constKeyword != null) buffer.write('const ');
    if (node.factoryKeyword != null) buffer.write('factory ');
    buffer.write(className);
    if (node.name != null) {
      buffer.write('.${node.name!.lexeme}');
    }
    buffer.write(node.parameters.toSource());
    return buffer.toString();
  }

  List<String> _extractAnnotations(NodeList<Annotation> metadata) {
    return metadata.map((a) => a.toSource()).toList();
  }

  String? _extractDocComment(Comment? comment) {
    if (comment == null) return null;
    return source.substring(comment.offset, comment.end);
  }

  String _buildFullBody(
      List<String> annotations, String? docComment, String body) {
    final buffer = StringBuffer();
    if (docComment != null) {
      buffer.writeln(docComment);
    }
    for (final annotation in annotations) {
      buffer.writeln(annotation);
    }
    buffer.write(body);
    return buffer.toString();
  }
}
