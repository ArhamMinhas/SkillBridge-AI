/// Shared Hero tags for cross-screen morph transitions — centralized so
/// two features (e.g. dashboard + profile) never accidentally duplicate a
/// tag and collide, and so both call sites reference one source of truth.
class HeroTags {
  HeroTags._();

  /// The user avatar — shared between the Home Dashboard header and
  /// Settings' profile hero, so tapping one morphs into the other instead
  /// of a plain cut.
  static const String userAvatar = 'user-avatar-hero';
}
