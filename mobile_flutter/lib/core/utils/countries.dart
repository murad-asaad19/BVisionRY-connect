/// One row in the FilterSheet country picker. The server stores `country`
/// as freeform text (matches the RN onboarding flow), so we ship the
/// English display [name] across the wire and treat [code] as informational.
class CountryOption {
  const CountryOption(this.code, this.name);

  /// ISO-3166-1 alpha-2 code (informational only).
  final String code;

  /// English display label sent to the server as the country filter value.
  final String name;

  /// Minimal seed list of common countries surfaced in the FilterSheet
  /// dropdown. Extend incrementally as the user base grows.
  static const List<CountryOption> all = <CountryOption>[
    CountryOption('AE', 'United Arab Emirates'),
    CountryOption('CA', 'Canada'),
    CountryOption('DE', 'Germany'),
    CountryOption('EG', 'Egypt'),
    CountryOption('ES', 'Spain'),
    CountryOption('FR', 'France'),
    CountryOption('GB', 'United Kingdom'),
    CountryOption('IN', 'India'),
    CountryOption('JO', 'Jordan'),
    CountryOption('LB', 'Lebanon'),
    CountryOption('SA', 'Saudi Arabia'),
    CountryOption('US', 'United States'),
  ];
}
