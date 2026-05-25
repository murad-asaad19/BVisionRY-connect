/// Trivial test clock used to drive the [MidnightInvalidator] from tests.
///
/// Provides a single mutable `DateTime` accessor that mirrors the
/// production `Clock` typedef (`DateTime Function()`) so [now] can be passed
/// directly as the override value for `clockProvider`.
class FakeClock {
  FakeClock(this._now);

  DateTime _now;

  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void setTo(DateTime t) => _now = t;
}
