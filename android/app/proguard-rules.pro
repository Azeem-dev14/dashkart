# R8 rules for the release build.
#
# Flutter's Gradle plugin and each plugin (Firebase, flutter_soloud, the
# physics library) ship their own consumer rules, so this file only has to
# cover what they do not.

# The Flutter engine references Play Core's deferred-components classes, which
# this app does not use and does not bundle. Without this R8 aborts the build
# on the missing classes.
-dontwarn com.google.android.play.core.**
