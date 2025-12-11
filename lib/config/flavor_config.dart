// Copyright © 2025 Apex Flow Group. All rights reserved.

const String flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'fDroid');

enum Flavor { googlePlay, fDroid }

class FlavorConfig {
  static final Flavor _flavor = _initFlavor();

  static Flavor _initFlavor() {
    return flavorString == 'googlePlay' ? Flavor.googlePlay : Flavor.fDroid;
  }

  static Flavor get flavor => _flavor;

  static bool get isGooglePlay => _flavor == Flavor.googlePlay;
  static bool get isFDroid => _flavor == Flavor.fDroid;

  static bool get hasTransferFeature => _flavor == Flavor.fDroid;
}
