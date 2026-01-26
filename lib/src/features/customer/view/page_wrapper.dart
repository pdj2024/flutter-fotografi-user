import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:provider/provider.dart';

// =========================================================
// ✨ PAGE WRAPPER - AUTO BOTTOM NAV CONTROL
// =========================================================

/// Wrapper untuk halaman yang ingin otomatis hide/show bottom nav
///
/// Usage:
/// ```dart
/// class MyDetailPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return FullScreenPage(
///       child: Scaffold(
///         appBar: AppBar(title: Text('Detail')),
///         body: MyContent(),
///       ),
///     );
///   }
/// }
/// ```
class FullScreenPage extends StatefulWidget {
  final Widget child;
  final bool showBottomNavOnPop;

  const FullScreenPage({
    Key? key,
    required this.child,
    this.showBottomNavOnPop = true,
  }) : super(key: key);

  @override
  State<FullScreenPage> createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage> with RouteAware {
  NavigationProvider? _navProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Cache provider reference
    _navProvider = context.read<NavigationProvider>();

    // ✅ Hide bottom nav when this page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navProvider != null) {
        _navProvider!.hideBottomNav();
        debugPrint('🙈 [FullScreenPage] Bottom nav hidden');
      }
    });
  }

  @override
  void dispose() {
    // ✅ FIXED: Don't use context in dispose
    // Use cached provider reference instead
    if (widget.showBottomNavOnPop && _navProvider != null) {
      // ✅ Check if should show (only if at root)
      if (_navProvider!.isAtRoot(_navProvider!.selectedIndex)) {
        // ✅ Direct call without post-frame callback
        _navProvider!.showBottomNav();
        debugPrint('📱 [FullScreenPage] Bottom nav shown (back to root)');
      }
    }
    
    _navProvider = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// =========================================================
// ✨ CUSTOM BACK BUTTON - AUTO BOTTOM NAV CONTROL
// =========================================================

/// Custom back button yang otomatis handle bottom nav visibility
///
/// Usage di AppBar:
/// ```dart
/// AppBar(
///   leading: CustomBackButton(),
///   title: Text('Detail'),
/// )
/// ```
class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const CustomBackButton({
    Key? key,
    this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () async {
        if (onPressed != null) {
          onPressed!();
          return;
        }

        // ✅ Use provider's handleBackButton (auto-updates visibility)
        final navProvider = context.read<NavigationProvider>();
        await navProvider.handleBackButton(context);
      },
    );
  }
}

// =========================================================
// ✨ ALTERNATIVE: WillPopScope Wrapper
// =========================================================

/// Wrapper dengan WillPopScope untuk handle back button
///
/// Usage:
/// ```dart
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AutoHideBottomNavPage(
///       child: Scaffold(
///         appBar: AppBar(title: Text('My Page')),
///         body: Content(),
///       ),
///     );
///   }
/// }
/// ```
class AutoHideBottomNavPage extends StatefulWidget {
  final Widget child;

  const AutoHideBottomNavPage({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AutoHideBottomNavPage> createState() => _AutoHideBottomNavPageState();
}

class _AutoHideBottomNavPageState extends State<AutoHideBottomNavPage> {
  NavigationProvider? _navProvider;

  @override
  void initState() {
    super.initState();

    // ✅ Hide bottom nav on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navProvider = context.read<NavigationProvider>();
        _navProvider?.hideBottomNav();
      }
    });
  }

  @override
  void dispose() {
    _navProvider = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!mounted) return true;
        
        final navProvider = context.read<NavigationProvider>();

        // ✅ Let provider handle the back action
        // It will auto-update visibility
        return await navProvider.handleBackButton(context);
      },
      child: widget.child,
    );
  }
}

// =========================================================
// ✨ MIXIN: For stateful widgets that need bottom nav control
// =========================================================

/// Mixin untuk StatefulWidget yang ingin kontrol bottom nav
///
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with BottomNavControlMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         leading: buildBackButton(context),
///         title: Text('My Page'),
///       ),
///       body: Content(),
///     );
///   }
/// }
/// ```
mixin BottomNavControlMixin<T extends StatefulWidget> on State<T> {
  NavigationProvider? _cachedNavProvider;

  @override
  void initState() {
    super.initState();
    _hideBottomNav();
  }

  @override
  void dispose() {
    _showBottomNavIfAtRoot();
    _cachedNavProvider = null;
    super.dispose();
  }

  void _hideBottomNav() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cachedNavProvider = context.read<NavigationProvider>();
        _cachedNavProvider?.hideBottomNav();
      }
    });
  }

  void _showBottomNavIfAtRoot() {
    // ✅ FIXED: Use cached provider, don't access context
    if (_cachedNavProvider != null) {
      if (_cachedNavProvider!.isAtRoot(_cachedNavProvider!.selectedIndex)) {
        _cachedNavProvider!.showBottomNav();
      }
    }
  }

  /// Helper method to build back button
  Widget buildBackButton(BuildContext context, {Color? color}) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () async {
        if (!mounted) return;
        
        final navProvider = context.read<NavigationProvider>();
        await navProvider.handleBackButton(context);
      },
    );
  }
}