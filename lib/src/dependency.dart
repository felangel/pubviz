import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart' as parse;

class Dependency implements Comparable<Dependency> {
  final String name;
  final VersionConstraint versionConstraint;
  final bool isDevDependency;

  bool _includesLatest;

  /// Also true if there is a pre-release version after the latest version
  bool get includesLatest => _includesLatest;

  set includesLatest(bool value) {
    assert(_includesLatest == null);
    assert(value != null);
    _includesLatest = value;
  }

  Dependency._(this.name, String versionConstraint, this.isDevDependency)
      : versionConstraint = _parseOrNull(versionConstraint);

  static Set<Dependency> getDependencies(parse.Pubspec pubspec) {
    final deps = <Dependency>{};

    _populateFromSection(pubspec.dependencies, deps, false);
    _populateFromSection(pubspec.devDependencies, deps, true);

    return deps;
  }

  static void _populateFromSection(
      Map<String, parse.Dependency> yaml, Set<Dependency> value, bool isDev) {
    yaml.forEach((String key, parse.Dependency constraint) {
      String constraintString;
      if (constraint is parse.HostedDependency) {
        constraintString = constraint.version.toString();
      } else {
        constraintString = constraint.toString();
      }

      final dep = Dependency._(key, constraintString, isDev);
      assert(!value.contains(dep));

      value.add(dep);
    });
  }

  @override
  bool operator ==(other) => other is Dependency && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  int compareTo(Dependency other) {
    if (other.isDevDependency == isDevDependency) {
      return name.compareTo(other.name);
    } else if (isDevDependency) {
      return 1;
    } else {
      return -1;
    }
  }

  @override
  String toString() {
    final devStr = isDevDependency ? '(dev)' : '';
    return '$name$devStr $versionConstraint';
  }
}

VersionConstraint _parseOrNull(String input) {
  try {
    return VersionConstraint.parse(input);
  } on FormatException {
    return VersionConstraint.empty;
  }
}
