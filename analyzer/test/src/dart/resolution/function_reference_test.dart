// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceResolutionTest);
    defineReflectiveTests(
        FunctionReferenceResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class FunctionReferenceResolutionTest extends PubPackageResolutionTest {
  test_constructorFunction_named() async {
    await assertNoErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = (A.foo)<int>;
''');

    assertFunctionReference(findNode.functionReference('(A.foo)<int>;'),
        findElement.constructor('foo'), 'A<int> Function()');
  }

  test_constructorFunction_unnamed() async {
    await assertNoErrorsInCode('''
class A<T> {
  A();
}

var x = (A.new)<int>;
''');

    assertFunctionReference(findNode.functionReference('(A.new)<int>;'),
        findElement.unnamedConstructor('A'), 'A<int> Function()');
  }

  test_constructorReference() async {
    await assertErrorsInCode('''
class A<T> {
  A.foo() {}
}

var x = A.foo<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 42,
          5),
    ]);

    assertFunctionReference(findNode.functionReference('A.foo<int>;'),
        findElement.constructor('foo'), 'dynamic');
  }

  test_explicitReceiver_dynamicTyped() async {
    await assertErrorsInCode('''
dynamic f(dynamic x) => x;

class C {
  T instanceMethod<T>(T t) => t;
}

main() {
  C c = new C();
  f(c).instanceMethod<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          102, 24),
    ]);

    assertFunctionReference(
        findNode.functionReference('f(c).instanceMethod<int>;'),
        null,
        'dynamic');
  }

  test_explicitReceiver_unknown() async {
    await assertErrorsInCode('''
bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_explicitReceiver_unknown_multipleProperties() async {
    await assertErrorsInCode('''
bar() {
  a.b.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 1),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_extensionGetter_extensionOverride() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 67, 8),
    ]);

    assertFunctionReference(findNode.functionReference('foo<int>;'),
        findElement.getter('foo'), 'dynamic');
  }

  test_extensionMethod() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_extensionMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_extensionMethod_extensionOverride() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_extensionMethod_extensionOverride_cascade() async {
    await assertErrorsInCode('''
class A {
  int foo = 0;
}

extension E on A {
  void foo<T>(T a) {}
}

bar(A a) {
  E(a)..foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 85, 1),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_extensionMethod_extensionOverride_static() async {
    await assertErrorsInCode('''
class A {}

extension E on A {
  static void foo<T>(T a) {}
}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER, 81,
          3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_extensionMethod_extensionOverride_unknown() async {
    await assertErrorsInCode('''
class A {}

extension E on A {}

bar(A a) {
  E(a).foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 51, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_extensionMethod_fromClassDeclaration() async {
    await assertNoErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}

extension E on A {
  void foo<T>(T a) {}
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceGetter_explicitReceiver() async {
    await assertErrorsInCode('''
class A {
  late void Function<T>(T) foo;
}

bar(A a) {
  a.foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 58, 5),
    ]);

    assertFunctionReference(findNode.functionReference('foo<int>;'),
        findElement.getter('foo'), 'void Function(int)');
  }

  test_instanceGetter_functionTyped() async {
    await assertNoErrorsInCode('''
abstract class A {
  late void Function<T>(T) foo;

  bar() {
    foo<int>;
  }
}

''');

    assertFunctionReference(findNode.functionReference('foo<int>;'),
        findElement.getter('foo'), 'void Function(int)');
  }

  test_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_field() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B {
  A a;
  B(this.a);
  bar() {
    a.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_otherExpression() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

void f(A? a, A b) {
  (a ?? b).foo<int>;
}
''');

    assertFunctionReference(findNode.functionReference('(a ?? b).foo<int>;'),
        findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_super() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
class B extends A {
  bar() {
    super.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_super_noMethod() async {
    await assertErrorsInCode('''
class A {
  bar() {
    super.foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 24, 9),
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 30, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_super_noSuper() async {
    await assertErrorsInCode('''
bar() {
  super.foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 10, 9),
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 10, 5),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>.m();
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_this() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    this.foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}
var a = A();

void bar() {
  a.foo<int>;
}
''');

    assertIdentifierTopGetRef(findNode.simple('a.'), 'a');
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void foo<T>(T a) {}
}
var a = A();
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference,
        findElement.importFind('package:test/a.dart').method('foo'),
        'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_topLevelVariable_prefix_unknown() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {}
var a = A();
''');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 47, 3),
    ]);

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_typeParameter() async {
    await assertErrorsInCode('''
bar<T>() {
  T.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 15, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_instanceMethod_explicitReceiver_variable() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a.foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_explicitReceiver_variable_cascade() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

bar(A a) {
  a..foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_inherited() async {
    await assertNoErrorsInCode('''
class A {
  void foo<T>(T a) {}
}

class B extends A {
  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
extension on Function {
  void m() {}
}
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int>.m();
  }
}
''');

    var reference = findNode.functionReference('foo<int>');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_instanceMethod_unknown() async {
    await assertErrorsInCode('''
class A {
  bar() {
    foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_localFunction() async {
    await assertNoErrorsInCode('''
void bar() {
  void foo<T>(T a) {}

  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.localFunction('foo'), 'void Function(int)');
  }

  test_localVariable() async {
    await assertNoErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.parameter('foo'), 'void Function(int)');
  }

  test_localVariable_typeVariable_boundToFunction() async {
    await assertErrorsInCode('''
void bar<T extends Function>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 40, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(reference, findElement.parameter('foo'), 'dynamic');
  }

  test_localVariable_typeVariable_functionTyped() async {
    await assertNoErrorsInCode('''
void bar<T extends void Function<U>(U)>(T foo) {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.parameter('foo'), 'void Function(int)');
  }

  test_localVariable_typeVariable_nonFunction() async {
    await assertErrorsInCode('''
void bar<T>(T foo) {
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 23, 3),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(reference, findElement.parameter('foo'), 'dynamic');
  }

  test_nonGenericFunction() async {
    await assertErrorsInCode('''
class A {
  void foo() {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 44, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function()');
  }

  test_otherExpression() async {
    await assertNoErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int>;
}
''');

    var reference = findNode.functionReference('(1 == 2 ? foo : bar)<int>;');
    assertType(reference, 'void Function(int)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_otherExpression_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode('''
void f(void Function<T>(T a) foo, void Function<T>(T a) bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''', [
      error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION,
          85,
          13),
    ]);

    var reference =
        findNode.functionReference('(1 == 2 ? foo : bar)<int, String>;');
    assertType(reference, 'void Function(dynamic)');
    // A ParenthesizedExpression has no element to assert on.
  }

  test_receiverIsDynamic() async {
    await assertErrorsInCode('''
bar(dynamic a) {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          19, 5),
    ]);

    assertFunctionReference(
        findNode.functionReference('a.foo<int>;'), null, 'dynamic');
  }

  test_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}

  bar() {
    foo<int>;
  }
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_staticMethod_explicitReceiver() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}

bar() {
  A.foo<int>;
}
''');

    assertClassRef(findNode.simple('A.'), findElement.class_('A'));
    assertFunctionReference(findNode.functionReference('foo<int>;'),
        findElement.method('foo'), 'void Function(int)');
  }

  test_staticMethod_explicitReceiver_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

bar() {
  a.A.foo<int>;
}
''');

    assertImportPrefix(findNode.simple('a.A'), findElement.prefix('a'));
    assertClassRef(findNode.simple('A.'),
        findElement.importFind('package:test/a.dart').class_('A'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference,
        findElement.importFind('package:test/a.dart').method('foo'),
        'void Function(int)');
  }

  test_staticMethod_explicitReceiver_prefix_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.TA.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference,
        findElement.importFind('package:test/a.dart').method('foo'),
        'void Function(int)');
  }

  test_staticMethod_explicitReceiver_typeAlias() async {
    await assertNoErrorsInCode('''
class A {
  static void foo<T>(T a) {}
}
typedef TA = A;

bar() {
  TA.foo<int>;
}
''');

    assertTypeAliasRef(findNode.simple('TA.'), findElement.typeAlias('TA'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(int)');
  }

  test_staticMethod_explicitReciver_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  static void foo<T>(T a) {}
}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.A.foo<int>;
}
''');

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference,
        findElement.importFind('package:test/a.dart').method('foo'),
        'void Function(int)');
  }

  test_tooFewTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T, U>(T a, U b) {}

  bar() {
    foo<int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 58, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(reference, findElement.method('foo'),
        'void Function(dynamic, dynamic)');
  }

  test_tooManyTypeArguments() async {
    await assertErrorsInCode('''
class A {
  void foo<T>(T a) {}

  bar() {
    foo<int, int>;
  }
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 50, 10),
    ]);

    var reference = findNode.functionReference('foo<int, int>;');
    assertFunctionReference(
        reference, findElement.method('foo'), 'void Function(dynamic)');
  }

  test_topLevelFunction() async {
    await assertNoErrorsInCode('''
void foo<T>(T a) {}

void bar() {
  foo<int>;
}
''');

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.topFunction('foo'), 'void Function(int)');
  }

  test_topLevelFunction_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''');

    assertImportPrefix(findNode.simple('a.f'), findElement.prefix('a'));
    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
      reference,
      findElement.importFind('package:test/a.dart').topFunction('foo'),
      'void Function(int)',
    );
  }

  test_topLevelFunction_importPrefix_asTargetOfFunctionCall() async {
    newFile('$testPackageLibPath/a.dart', content: '''
void foo<T>(T arg) {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;

extension on Function {
  void m() {}
}
void bar() {
  a.foo<int>.m();
}
''');

    assertImportPrefix(findNode.simple('a.f'), findElement.prefix('a'));
    var reference = findNode.functionReference('foo<int>');
    assertFunctionReference(
      reference,
      findElement.importFind('package:test/a.dart').topFunction('foo'),
      'void Function(int)',
    );
  }

  test_topLevelFunction_prefix_unknownPrefix() async {
    await assertErrorsInCode('''
bar() {
  prefix.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 10, 6),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_topLevelFunction_targetOfFunctionCall() async {
    await assertNoErrorsInCode('''
void foo<T>(T arg) {}

extension on Function {
  void m() {}
}
void bar() {
  foo<int>.m();
}
''');

    assertFunctionReference(findNode.functionReference('foo<int>'),
        findElement.topFunction('foo'), 'void Function(int)');
  }

  test_topLevelVariable_prefix_unknownIdentifier() async {
    newFile('$testPackageLibPath/a.dart', content: '');
    await assertErrorsInCode('''
import 'a.dart' as prefix;

bar() {
  prefix.a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 45, 1),
    ]);

    assertImportPrefix(
        findNode.simple('prefix.'), findElement.prefix('prefix'));
    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_typeAlias_function_unknownProperty() async {
    await assertErrorsInCode('''
typedef Cb = void Function();

var a = Cb.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 42, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_typeAlias_typeVariable_unknownProperty() async {
    await assertErrorsInCode('''
typedef T<E> = E;

var a = T.foo<int>;
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 29, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_unknownIdentifier() async {
    await assertErrorsInCode('''
void bar() {
  foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_unknownIdentifier_explicitReceiver() async {
    await assertErrorsInCode('''
class A {}

class B {
  bar(A a) {
    a.foo<int>;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }

  test_unknownIdentifier_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '');
    await assertErrorsInCode('''
import 'a.dart' as a;

void bar() {
  a.foo<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 40, 3),
    ]);

    assertFunctionReference(
        findNode.functionReference('foo<int>;'), null, 'dynamic');
  }
}

@reflectiveTest
class FunctionReferenceResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_localVariable() async {
    // This code includes a disallowed type instantiation (local variable),
    // but in the case that the experiment is not enabled, we suppress the
    // associated error.
    await assertErrorsInCode('''
void bar(void Function<T>(T a) foo) {
  foo<int>;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 43, 5),
    ]);

    var reference = findNode.functionReference('foo<int>;');
    assertFunctionReference(
        reference, findElement.parameter('foo'), 'void Function(int)');
  }
}
