import 'package:flutter/material.dart';
import 'package:real_banking/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ATM data model
// ─────────────────────────────────────────────────────────────────────────────
class _AtmLocation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String distance;
  final bool is24h;
  final bool hasCardless;
  final bool hasDeposit;
  final bool isDriveThrough;
  final bool isNexus;
  final double distanceMiles; // for numeric sorting
  final Offset mapPosition; // fractional 0..1

  const _AtmLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.distance,
    required this.is24h,
    required this.hasCardless,
    required this.hasDeposit,
    required this.isDriveThrough,
    required this.isNexus,
    required this.distanceMiles,
    required this.mapPosition,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Static ATM data (8+ ATMs)
// ─────────────────────────────────────────────────────────────────────────────
const _kAtms = <_AtmLocation>[
  _AtmLocation(
    id: 'nx-001',
    name: 'Nexus Digital — 5th Avenue Branch',
    address: '350 5th Ave, New York, NY 10118',
    phone: '(212) 555-0101',
    distance: '0.1 mi',
    distanceMiles: 0.1,
    is24h: true,
    hasCardless: true,
    hasDeposit: true,
    isDriveThrough: false,
    isNexus: true,
    mapPosition: Offset(0.42, 0.38),
  ),
  _AtmLocation(
    id: 'nx-002',
    name: 'Nexus Digital — Times Square',
    address: '1 Times Square, New York, NY 10036',
    phone: '(212) 555-0212',
    distance: '0.4 mi',
    distanceMiles: 0.4,
    is24h: true,
    hasCardless: true,
    hasDeposit: false,
    isDriveThrough: false,
    isNexus: true,
    mapPosition: Offset(0.58, 0.24),
  ),
  _AtmLocation(
    id: 'ch-001',
    name: 'Chase Bank ATM — Midtown East',
    address: '510 Lexington Ave, New York, NY 10017',
    phone: '(212) 555-0333',
    distance: '0.7 mi',
    distanceMiles: 0.7,
    is24h: true,
    hasCardless: false,
    hasDeposit: true,
    isDriveThrough: false,
    isNexus: false,
    mapPosition: Offset(0.72, 0.44),
  ),
  _AtmLocation(
    id: 'wf-001',
    name: 'Wells Fargo ATM — Park Avenue',
    address: '299 Park Ave, New York, NY 10171',
    phone: '(212) 555-0444',
    distance: '0.9 mi',
    distanceMiles: 0.9,
    is24h: false,
    hasCardless: false,
    hasDeposit: true,
    isDriveThrough: false,
    isNexus: false,
    mapPosition: Offset(0.25, 0.60),
  ),
  _AtmLocation(
    id: 'nx-003',
    name: 'Nexus Digital — Grand Central',
    address: '87 E 42nd St, New York, NY 10017',
    phone: '(212) 555-0555',
    distance: '1.2 mi',
    distanceMiles: 1.2,
    is24h: true,
    hasCardless: true,
    hasDeposit: true,
    isDriveThrough: false,
    isNexus: true,
    mapPosition: Offset(0.64, 0.68),
  ),
  _AtmLocation(
    id: 'bac-001',
    name: 'Bank of America ATM — West Side',
    address: '225 W 34th St, New York, NY 10122',
    phone: '(212) 555-0666',
    distance: '1.5 mi',
    distanceMiles: 1.5,
    is24h: true,
    hasCardless: false,
    hasDeposit: true,
    isDriveThrough: true,
    isNexus: false,
    mapPosition: Offset(0.18, 0.30),
  ),
  _AtmLocation(
    id: 'ci-001',
    name: 'Citibank ATM — Columbus Circle',
    address: '1 Columbus Cir, New York, NY 10023',
    phone: '(212) 555-0777',
    distance: '1.8 mi',
    distanceMiles: 1.8,
    is24h: false,
    hasCardless: false,
    hasDeposit: false,
    isDriveThrough: false,
    isNexus: false,
    mapPosition: Offset(0.83, 0.18),
  ),
  _AtmLocation(
    id: 'nx-004',
    name: 'Nexus Digital — Brooklyn Bridge',
    address: '4 MetroTech Ctr, Brooklyn, NY 11201',
    phone: '(718) 555-0888',
    distance: '2.1 mi',
    distanceMiles: 2.1,
    is24h: true,
    hasCardless: true,
    hasDeposit: false,
    isDriveThrough: false,
    isNexus: true,
    mapPosition: Offset(0.50, 0.82),
  ),
  _AtmLocation(
    id: 'td-001',
    name: 'TD Bank ATM — Financial District',
    address: '70 Pine St, New York, NY 10005',
    phone: '(212) 555-0999',
    distance: '2.5 mi',
    distanceMiles: 2.5,
    is24h: true,
    hasCardless: false,
    hasDeposit: true,
    isDriveThrough: true,
    isNexus: false,
    mapPosition: Offset(0.33, 0.72),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Filter enum
// ─────────────────────────────────────────────────────────────────────────────
enum _AtmFilter { all, open24h, cardless, nearby }

// ─────────────────────────────────────────────────────────────────────────────
// ATM Locator Screen
// ─────────────────────────────────────────────────────────────────────────────
class AtmLocatorScreen extends StatefulWidget {
  const AtmLocatorScreen({super.key});

  @override
  State<AtmLocatorScreen> createState() => _AtmLocatorScreenState();
}

class _AtmLocatorScreenState extends State<AtmLocatorScreen> {
  _AtmFilter _filter = _AtmFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AtmLocation> get _filteredAtms {
    var list = _kAtms.toList();

    // Apply filter chip
    switch (_filter) {
      case _AtmFilter.open24h:
        list = list.where((a) => a.is24h).toList();
        break;
      case _AtmFilter.cardless:
        list = list.where((a) => a.hasCardless).toList();
        break;
      case _AtmFilter.nearby:
        list = list.where((a) => a.distanceMiles <= 1.0).toList();
        break;
      case _AtmFilter.all:
        break;
    }

    // Apply search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.address.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  void _showDirectionsSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation_rounded,
                color: AppColors.primaryContainer, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Opening maps for "$name"…',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAtms;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ATM Locator',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppColors.primaryContainer),
                        const SizedBox(width: 4),
                        const Text(
                          'New York, NY · GPS Enabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            title: const Text(
              'ATM Locator',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Search bar ────────────────────────────────────────────
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded,
                          color: AppColors.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search by name or address…',
                            hintStyle: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.close_rounded,
                                color: AppColors.onSurfaceVariant, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Filter chips ──────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipWidget(
                        label: 'All',
                        icon: Icons.grid_view_rounded,
                        selected: _filter == _AtmFilter.all,
                        onTap: () => setState(() => _filter = _AtmFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipWidget(
                        label: '24/7',
                        icon: Icons.access_time_filled_rounded,
                        selected: _filter == _AtmFilter.open24h,
                        onTap: () =>
                            setState(() => _filter = _AtmFilter.open24h),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipWidget(
                        label: 'Cardless',
                        icon: Icons.phonelink_rounded,
                        selected: _filter == _AtmFilter.cardless,
                        onTap: () =>
                            setState(() => _filter = _AtmFilter.cardless),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipWidget(
                        label: 'Nearby',
                        icon: Icons.near_me_rounded,
                        selected: _filter == _AtmFilter.nearby,
                        onTap: () =>
                            setState(() => _filter = _AtmFilter.nearby),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Fake map view ─────────────────────────────────────────
                _FakeMapView(
                  allAtms: _kAtms,
                  visibleAtms: filtered,
                ),
                const SizedBox(height: 20),

                // ── Results label ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NEARBY ATMs',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filtered.length} found',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── ATM list ──────────────────────────────────────────────
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.atm_rounded,
                                color: AppColors.onSurfaceVariant, size: 28),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No ATMs match your filter',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (atm) => _AtmCard(
                      atm: atm,
                      onDirections: () => _showDirectionsSnack(atm.name),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake map view
// ─────────────────────────────────────────────────────────────────────────────
class _FakeMapView extends StatelessWidget {
  final List<_AtmLocation> allAtms;
  final List<_AtmLocation> visibleAtms;

  const _FakeMapView({
    required this.allAtms,
    required this.visibleAtms,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 240,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Dark map background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF141820),
                        Color(0xFF0E1218),
                        Color(0xFF0A0D12),
                      ],
                    ),
                  ),
                ),

                // Grid overlay — simulates map tiles
                CustomPaint(
                  size: Size(w, h),
                  painter: _GridPainter(),
                ),

                // Road network
                CustomPaint(
                  size: Size(w, h),
                  painter: _RoadsPainter(),
                ),

                // City block fills
                CustomPaint(
                  size: Size(w, h),
                  painter: _BlocksPainter(),
                ),

                // User location pulse
                Positioned(
                  left: w * 0.42 - 12,
                  top: h * 0.38 - 12,
                  child: const _PulseIndicator(),
                ),

                // "You" label
                Positioned(
                  left: w * 0.42 + 10,
                  top: h * 0.38 - 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // ATM pins
                ...allAtms.map((atm) {
                  final visible = visibleAtms.contains(atm);
                  return Positioned(
                    left: w * atm.mapPosition.dx - 15,
                    top: h * atm.mapPosition.dy - 30,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: visible ? 1.0 : 0.2,
                      child: _MapPin(atm: atm),
                    ),
                  );
                }),

                // Map controls overlay (top right)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Column(
                    children: [
                      _MapControlButton(icon: Icons.add_rounded),
                      const SizedBox(height: 4),
                      _MapControlButton(icon: Icons.remove_rounded),
                    ],
                  ),
                ),

                // Legend / label (bottom left)
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0D12).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.outlineVariant.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Nexus ATM',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Partner ATM',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Demo badge
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DEMO MAP',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map control button (zoom +/-)
// ─────────────────────────────────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  const _MapControlButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D12).withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(icon, color: AppColors.onSurfaceVariant, size: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1F2C)
      ..strokeWidth = 0.5;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mainRoad = Paint()
      ..color = const Color(0xFF1E2535)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final sideRoad = Paint()
      ..color = const Color(0xFF181E2A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Main arteries
    canvas.drawLine(
        Offset(0, size.height * 0.38),
        Offset(size.width, size.height * 0.38),
        mainRoad);
    canvas.drawLine(
        Offset(size.width * 0.42, 0),
        Offset(size.width * 0.42, size.height),
        mainRoad);
    canvas.drawLine(
        Offset(0, size.height * 0.68),
        Offset(size.width, size.height * 0.68),
        mainRoad);
    canvas.drawLine(
        Offset(size.width * 0.72, 0),
        Offset(size.width * 0.72, size.height),
        mainRoad);

    // Side streets
    canvas.drawLine(
        Offset(0, size.height * 0.20),
        Offset(size.width, size.height * 0.20),
        sideRoad);
    canvas.drawLine(
        Offset(0, size.height * 0.54),
        Offset(size.width, size.height * 0.54),
        sideRoad);
    canvas.drawLine(
        Offset(size.width * 0.22, 0),
        Offset(size.width * 0.22, size.height),
        sideRoad);
    canvas.drawLine(
        Offset(size.width * 0.58, 0),
        Offset(size.width * 0.58, size.height),
        sideRoad);

    // Diagonal avenue
    canvas.drawLine(
        Offset(size.width * 0.15, 0),
        Offset(size.width * 0.88, size.height),
        sideRoad..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BlocksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()
      ..color = const Color(0xFF131922)
      ..style = PaintingStyle.fill;

    // Draw a few city blocks as rectangles
    final blocks = [
      Rect.fromLTWH(
          size.width * 0.0, size.height * 0.0,
          size.width * 0.20, size.height * 0.17),
      Rect.fromLTWH(
          size.width * 0.24, size.height * 0.0,
          size.width * 0.16, size.height * 0.17),
      Rect.fromLTWH(
          size.width * 0.44, size.height * 0.0,
          size.width * 0.12, size.height * 0.17),
      Rect.fromLTWH(
          size.width * 0.74, size.height * 0.0,
          size.width * 0.26, size.height * 0.17),
      Rect.fromLTWH(
          size.width * 0.0, size.height * 0.22,
          size.width * 0.20, size.height * 0.13),
      Rect.fromLTWH(
          size.width * 0.24, size.height * 0.22,
          size.width * 0.16, size.height * 0.13),
      Rect.fromLTWH(
          size.width * 0.44, size.height * 0.22,
          size.width * 0.12, size.height * 0.13),
      Rect.fromLTWH(
          size.width * 0.60, size.height * 0.22,
          size.width * 0.10, size.height * 0.13),
      Rect.fromLTWH(
          size.width * 0.74, size.height * 0.22,
          size.width * 0.26, size.height * 0.13),
      Rect.fromLTWH(
          size.width * 0.0, size.height * 0.40,
          size.width * 0.20, size.height * 0.11),
      Rect.fromLTWH(
          size.width * 0.24, size.height * 0.40,
          size.width * 0.16, size.height * 0.11),
      Rect.fromLTWH(
          size.width * 0.44, size.height * 0.40,
          size.width * 0.26, size.height * 0.11),
      Rect.fromLTWH(
          size.width * 0.74, size.height * 0.40,
          size.width * 0.26, size.height * 0.11),
      Rect.fromLTWH(
          size.width * 0.0, size.height * 0.56,
          size.width * 0.40, size.height * 0.09),
      Rect.fromLTWH(
          size.width * 0.44, size.height * 0.56,
          size.width * 0.26, size.height * 0.09),
      Rect.fromLTWH(
          size.width * 0.74, size.height * 0.56,
          size.width * 0.26, size.height * 0.09),
      Rect.fromLTWH(
          size.width * 0.0, size.height * 0.70,
          size.width * 0.40, size.height * 0.30),
      Rect.fromLTWH(
          size.width * 0.44, size.height * 0.70,
          size.width * 0.26, size.height * 0.30),
      Rect.fromLTWH(
          size.width * 0.74, size.height * 0.70,
          size.width * 0.26, size.height * 0.30),
    ];

    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(2)),
        blockPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated pulse indicator (user location)
// ─────────────────────────────────────────────────────────────────────────────
class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map pin
// ─────────────────────────────────────────────────────────────────────────────
class _MapPin extends StatelessWidget {
  final _AtmLocation atm;
  const _MapPin({required this.atm});

  @override
  Widget build(BuildContext context) {
    final color = atm.isNexus ? AppColors.primaryContainer : AppColors.warning;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.55),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            atm.isNexus
                ? Icons.account_balance_rounded
                : Icons.atm_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
        Container(
          width: 2,
          height: 6,
          color: color,
        ),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: atm.is24h ? AppColors.success : AppColors.warning,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip widget
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChipWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATM card
// ─────────────────────────────────────────────────────────────────────────────
class _AtmCard extends StatelessWidget {
  final _AtmLocation atm;
  final VoidCallback onDirections;

  const _AtmCard({required this.atm, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final typeColor =
        atm.isNexus ? AppColors.primaryContainer : AppColors.warning;
    final statusColor = atm.is24h ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ── Top row ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    atm.isNexus
                        ? Icons.account_balance_rounded
                        : Icons.atm_rounded,
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + network badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              atm.name,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: typeColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              atm.isNexus ? 'STCU' : 'PARTNER',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              atm.address,
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Phone
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 12,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            atm.phone,
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Status + distance row ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        atm.is24h ? 'Open 24/7' : 'Limited Hours',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Distance badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 11,
                          color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        atm.distance,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Feature pills ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (atm.hasCardless)
                  _FeaturePill(
                    icon: Icons.phonelink_rounded,
                    label: 'Cardless',
                    color: AppColors.primaryContainer,
                  ),
                if (atm.hasDeposit)
                  _FeaturePill(
                    icon: Icons.savings_rounded,
                    label: 'Deposit',
                    color: AppColors.success,
                  ),
                if (atm.isDriveThrough)
                  _FeaturePill(
                    icon: Icons.directions_car_rounded,
                    label: 'Drive-Thru',
                    color: AppColors.warning,
                  ),
                if (!atm.hasCardless && !atm.hasDeposit && !atm.isDriveThrough)
                  _FeaturePill(
                    icon: Icons.credit_card_rounded,
                    label: 'Card Only',
                    color: AppColors.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Divider + action row ──────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineVariant.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                // Copy address button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Address copied to clipboard'),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        ),
                      );
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 14,
                              color: AppColors.onSurfaceVariant),
                          SizedBox(width: 6),
                          Text(
                            'Copy Address',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Get Directions
                Expanded(
                  child: GestureDetector(
                    onTap: onDirections,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.electricGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryContainer.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Get Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature pill
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
