import 'package:test/test.dart';
import 'package:flyde/features/build_server/cache/dependencies/dependency_graph.dart';

void main() {
  test('Dependencies are mapped correctly', () {
    final ids = {'a', 'b', 'c', 'd'};
    final graph = DependencyGraph.fromIds(ids);

    graph.connect('a', {'b', 'c'});
    graph.connect('b', {'c', 'd'});

    expect(graph.dependencies('a'), unorderedEquals(['b', 'c']));
    expect(graph.transitiveDependencies('a'), unorderedEquals(['b', 'c', 'd']));
    expect(graph.dependents('a'), isEmpty);
    expect(graph.transitiveDependents('a'), isEmpty);

    expect(graph.dependencies('b'), unorderedEquals(['c', 'd']));
    expect(graph.transitiveDependencies('b'), unorderedEquals(['c', 'd']));
    expect(graph.dependents('b'), unorderedEquals(['a']));
    expect(graph.transitiveDependents('b'), unorderedEquals(['a']));

    expect(graph.dependencies('c'), isEmpty);
    expect(graph.transitiveDependencies('c'), isEmpty);
    expect(graph.dependents('c'), unorderedEquals(['a', 'b']));
    expect(graph.transitiveDependents('c'), unorderedEquals(['a', 'b']));

    expect(graph.dependencies('d'), isEmpty);
    expect(graph.transitiveDependencies('d'), isEmpty);
    expect(graph.dependents('d'), unorderedEquals(['b']));
    expect(graph.transitiveDependents('d'), unorderedEquals(['a', 'b']));
  });

  test('Can handle cross dependencies', () {
    final ids = {'a', 'b'};
    final graph = DependencyGraph.fromIds(ids);

    graph.connect('a', {'b'});
    graph.connect('b', {'a'});

    expect(graph.dependencies('a'), unorderedEquals(['b']));
    expect(graph.transitiveDependencies('a'), unorderedEquals(['b', 'a']));
    expect(graph.dependents('b'), unorderedEquals(['a']));
    expect(graph.transitiveDependents('b'), unorderedEquals(['a', 'b']));
  });

  test('Can be updated', () {
    final oldIds = {'a', 'b', 'c', 'd'};
    final graph = DependencyGraph.fromIds(oldIds);
    final newIds = {'a', 'b', 'd', 'e'};

    graph.connect('a', {'b', 'c'});
    graph.connect('b', {'d'});
    graph.connect('c', {'d'});
    graph.connect('d', {'a'});

    graph.update(newIds);

    // (re)connect nodes with the newly added 'e'
    graph.connect('a', {'b', 'e'});
    graph.connect('e', {'d'});

    expect(graph.dependencies('a'), unorderedEquals(['b', 'e']));
    expect(graph.transitiveDependencies('a'), unorderedEquals(['b', 'e', 'd', 'a']));
    expect(graph.dependents('a'), unorderedEquals(['d']));
    expect(graph.transitiveDependents('a'), unorderedEquals(['d', 'e', 'b', 'a']));

    expect(graph.dependencies('b'), unorderedEquals(['d']));
    expect(graph.transitiveDependencies('b'), unorderedEquals(['b', 'e', 'd', 'a']));
    expect(graph.dependents('b'), unorderedEquals(['a']));
    expect(graph.transitiveDependents('b'), unorderedEquals(['d', 'e', 'b', 'a']));

    expect(graph.dependencies('d'), unorderedEquals(['a']));
    expect(graph.transitiveDependencies('d'), unorderedEquals(['b', 'e', 'd', 'a']));
    expect(graph.dependents('d'), unorderedEquals(['b', 'e']));
    expect(graph.transitiveDependents('d'), unorderedEquals(['d', 'e', 'b', 'a']));

    expect(graph.dependencies('e'), unorderedEquals(['d']));
    expect(graph.transitiveDependencies('e'), unorderedEquals(['b', 'e', 'd', 'a']));
    expect(graph.dependents('e'), unorderedEquals(['a']));
    expect(graph.transitiveDependents('e'), unorderedEquals(['d', 'e', 'b', 'a']));

    final errorMatcher = throwsA(isA<StateError>());

    expect(() => graph.dependencies('c'), errorMatcher);
    expect(() => graph.transitiveDependencies('c'), errorMatcher);
    expect(() => graph.dependents('c'), errorMatcher);
    expect(() => graph.transitiveDependents('c'), errorMatcher);
  });
}
