/// Yaw rate, in radians per second about +Y, for a steering position.
///
/// [steer] runs -1 (full left) to +1 (full right); [rate] is the unsigned turn
/// rate the kart can manage right now. A positive result turns the nose
/// towards the **right of the screen**.
///
/// The sign is not the one a right-handed intuition gives, and it was wrong
/// once — left and right came out swapped. flutter_scene's world is
/// left-handed: its camera builds screen-right as `up × forward`, where a
/// right-handed one builds `forward × up`. In that world a positive rotation
/// about +Y carries the nose towards screen-right, so right steering is a
/// *positive* yaw rate. `steering_test.dart` checks this against the engine's
/// own camera rather than against the reasoning in this comment.
double yawRateForSteer({required double steer, required double rate}) =>
    steer * rate;
