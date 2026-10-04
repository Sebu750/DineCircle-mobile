// Material exports its own `MenuStyle`; the dining model owns that name here.
import 'package:flutter/material.dart' hide MenuStyle;
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/nav.dart';
import '../data/app_scope.dart';
import '../data/image_catalog.dart';
import '../models/dinner_event.dart';
import '../models/restaurant.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Cover photos offered when composing a table — venue rooms first, then the
/// food shots that carry most of the cards in the feed.
const _coverPool = <String>[
  Img.izakaya,
  Img.bistro,
  Img.gardenTerrace,
  Img.wineCellar,
  Img.farmKitchen,
  Img.longTable,
  Img.trattoria,
  Img.rooftop,
  Img.omakase,
  Img.fireFeast,
  Img.wineTasting,
  Img.supperClub,
  Img.dessertTasting,
];

const _durations = <int>[120, 150, 180, 210];

const _timeSlots = <(int, int)>[
  (11, 30),
  (12, 30),
  (13, 30),
  (16, 0),
  (17, 30),
  (18, 0),
  (18, 30),
  (19, 0),
  (19, 30),
  (20, 0),
  (20, 30),
  (21, 0),
  (21, 30),
];

const _includedPool = <String>[
  'Welcome drink',
  'Wine pairing',
  'Coffee & dessert',
  'Service included',
  'Free-flow drinks',
  'Take-home box',
];

const _vibePool = <String>[
  'Long table',
  'Wine pairing',
  'Vegetarian friendly',
  'Rooftop terrace',
  'Live music',
  'Solo friendly',
  'Chef\'s counter',
  'Outdoor',
];

/// Four-step wizard that turns a room, a date and a menu into a bookable
/// table. Publishing writes straight into the store, so the new table is on
/// Discover the moment it is created.
class CreateDinnerScreen extends StatefulWidget {
  const CreateDinnerScreen({super.key});

  @override
  State<CreateDinnerScreen> createState() => _CreateDinnerScreenState();
}

class _CreateDinnerScreenState extends State<CreateDinnerScreen> {
  static const _stepCount = 4;
  static const _eyebrows = <String>[
    'The room',
    'The table',
    'The menu',
    'The price',
  ];
  static const _titles = <String>[
    'Where are you hosting?',
    'When, and for how many?',
    'What goes on the table?',
    'What does a seat cost?',
  ];
  static const _notes = <String>[
    'Partner rooms already know how to host a DineCircle table.',
    'A clear title and an honest one-liner fill more seats than anything else.',
    'Write the menu you would happily eat twice.',
    'You keep every seat you sell, minus the platform fee.',
  ];

  final _page = PageController();
  final _title = TextEditingController();
  final _tagline = TextEditingController();
  final _description = TextEditingController();
  final _hostNote = TextEditingController();

  int _step = 0;
  String? _createdId;

  Restaurant? _venue;
  String _cover = Img.longTable;
  DateTime _day = _dayOffset(1);
  int _hour = 20;
  int _minute = 0;
  int _duration = 150;
  int _seats = 8;
  double _price = 58;
  bool _priceTouched = false;
  bool _titleAuto = true;
  ExperienceType _type = ExperienceType.dinner;
  Audience _audience = Audience.public;
  MenuStyle _menuStyle = MenuStyle.familyStyle;
  final List<MenuItem> _courses = [];
  final Set<String> _included = {'Welcome drink', 'Service included'};
  final Set<String> _vibes = {'Long table', 'Solo friendly'};

  static DateTime _dayOffset(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _hour, _minute);

  bool get _isLast => _step == _stepCount - 1;

  bool get _canContinue => switch (_step) {
    0 => _venue != null,
    1 => _title.text.trim().isNotEmpty,
    2 => _courses.isNotEmpty,
    _ => _price > 0,
  };

  String? get _blockNote => switch (_step) {
    0 => _venue == null ? 'Pick a room to continue' : null,
    1 => _title.text.trim().isEmpty ? 'Give the table a title' : null,
    2 => _courses.isEmpty ? 'Add a course, or start from a template' : null,
    _ => null,
  };

  // ── Mutations ────────────────────────────────────────────────────────────
  void _syncAutoTitle() {
    final venue = _venue;
    if (!_titleAuto || venue == null) return;
    _title.text = '${_type.label} at ${venue.name}';
  }

  void _onTitleChanged(String value) => setState(() {
    _titleAuto = value.trim().isEmpty;
    _syncAutoTitle();
  });

  void _selectVenue(Restaurant venue) {
    setState(() {
      _venue = venue;
      _cover = venue.heroAsset;
      if (!_priceTouched) _price = context.app.suggestedPrice(venue);
      _syncAutoTitle();
    });
  }

  void _selectCover(String asset) {
    HapticFeedback.selectionClick();
    setState(() => _cover = asset);
  }

  void _selectType(ExperienceType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _syncAutoTitle();
    });
  }

  void _selectDay(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() => _day = day);
  }

  void _selectTime(int hour, int minute) {
    HapticFeedback.selectionClick();
    setState(() {
      _hour = hour;
      _minute = minute;
    });
  }

  void _selectDuration(int minutes) => setState(() => _duration = minutes);

  void _setSeats(int seats) => setState(() => _seats = seats);

  void _selectAudience(Audience audience) {
    HapticFeedback.selectionClick();
    setState(() => _audience = audience);
  }

  void _selectMenuStyle(MenuStyle style) {
    HapticFeedback.selectionClick();
    setState(() => _menuStyle = style);
  }

  void _toggleIncluded(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_included.remove(value)) _included.add(value);
    });
  }

  void _toggleVibe(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_vibes.remove(value)) _vibes.add(value);
    });
  }

  void _useTemplate() {
    HapticFeedback.selectionClick();
    setState(() {
      _courses
        ..clear()
        ..addAll(_templateFor(_type));
    });
  }

  void _addCourse(MenuItem item) => setState(() => _courses.add(item));

  void _replaceCourse(int index, MenuItem item) =>
      setState(() => _courses[index] = item);

  void _removeCourse(int index) {
    HapticFeedback.selectionClick();
    setState(() => _courses.removeAt(index));
  }

  void _setPrice(double value) => setState(() {
    _price = value;
    _priceTouched = true;
  });

  static List<MenuItem> _templateFor(ExperienceType type) => switch (type) {
    ExperienceType.tasting => const [
      MenuItem(
        name: 'Something salty to start',
        description: 'Small, warm and eaten with the first pour.',
      ),
      MenuItem(
        name: 'Three pours, side by side',
        description: 'Chosen so you can taste them against each other.',
        isSignature: true,
      ),
      MenuItem(
        name: 'One sweet thing',
        description: 'Made in house, nothing complicated.',
      ),
    ],
    ExperienceType.workshop => const [
      MenuItem(
        name: 'Hands-on block',
        description: 'Everything you make, you eat.',
      ),
      MenuItem(
        name: 'The shared table',
        description: 'Your dishes, served family style.',
        isSignature: true,
      ),
      MenuItem(
        name: 'Tea & take-home',
        description: 'Recipe cards and a box to leave with.',
      ),
    ],
    ExperienceType.brunch => const [
      MenuItem(
        name: 'Coffee & pastry',
        description: 'A slow start, nothing rushed.',
      ),
      MenuItem(
        name: 'The main plate',
        description: 'Eggs, greens and something baked.',
        isSignature: true,
      ),
      MenuItem(name: 'Dessert', description: 'One thing, done properly.'),
    ],
    ExperienceType.supperClub => const [
      MenuItem(
        name: 'Course one',
        description: 'Written on the day, based on what the market had.',
      ),
      MenuItem(
        name: 'Course two',
        description: 'The one the table will still be talking about.',
        isSignature: true,
      ),
      MenuItem(
        name: 'Course three',
        description: 'Something sweet, slightly strange.',
      ),
    ],
    ExperienceType.festival => const [
      MenuItem(
        name: 'Grazing board',
        description: 'Everything from the fire, all at once.',
      ),
      MenuItem(
        name: 'Street plates',
        description: 'Three small things, eaten standing up.',
        isSignature: true,
      ),
      MenuItem(
        name: 'Sweet finish',
        description: 'Something fried and sugared.',
      ),
    ],
    ExperienceType.dinner => const [
      MenuItem(
        name: 'Bread & butter',
        description: 'Warm, salted, impossible to ignore.',
      ),
      MenuItem(name: 'Starter', description: 'Seasonal and vegetable-forward.'),
      MenuItem(
        name: 'Main',
        description: 'The centre of the table.',
        isSignature: true,
      ),
      MenuItem(name: 'Dessert', description: 'The reason nobody leaves early.'),
    ],
  };

  // ── Navigation ───────────────────────────────────────────────────────────
  void _next() {
    if (!_canContinue || _isLast) return;
    HapticFeedback.selectionClick();
    setState(() => _step++);
    _page.animateToPage(_step, duration: Motion.slow, curve: Motion.emphasized);
  }

  void _back() {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _step--);
    _page.animateToPage(_step, duration: Motion.slow, curve: Motion.emphasized);
  }

  void _publish() {
    final venue = _venue;
    if (venue == null) return;
    final app = context.app;
    HapticFeedback.mediumImpact();

    final gallery = <String>[
      _cover,
      for (final asset in _coverPool)
        if (asset != _cover) asset,
    ].take(3).toList(growable: false);

    final event = DinnerEvent(
      id: 'e_${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      tagline: _tagline.text.trim().isEmpty
          ? '$_seats seats at ${venue.name}, hosted by you.'
          : _tagline.text.trim(),
      description: _description.text.trim().isEmpty
          ? 'A ${_menuStyle.label.toLowerCase()} table at ${venue.name} in '
                '${venue.neighborhood}. ${_courses.length} courses, '
                '$_seats seats and a host who is on the night.'
          : _description.text.trim(),
      hostId: app.me?.id ?? '',
      restaurantId: venue.id,
      imageAsset: _cover,
      gallery: gallery,
      start: _start,
      durationMinutes: _duration,
      seatsTotal: _seats,
      seatsTaken: 0,
      pricePerSeat: _price,
      type: _type,
      audience: _audience,
      menuStyle: _menuStyle,
      included: _included.isEmpty
          ? ['Table of $_seats', 'Service included']
          : _included.toList(growable: false),
      tags: _vibes.isEmpty
          ? [_type.label, venue.cuisine]
          : _vibes.toList(growable: false),
      menu: List<MenuItem>.unmodifiable(_courses),
      hostNote: _hostNote.text.trim(),
      attendeeIds: const [],
    );

    app.publish(event);
    setState(() => _createdId = event.id);
  }

  Future<void> _confirmClose() async {
    final navigator = Navigator.of(context);
    if (_step == 0 && _venue == null) {
      navigator.maybePop();
      return;
    }
    final discard = await DcSheet.show<bool>(
      context,
      builder: (sheetContext) => DcSheet(
        title: 'Discard this table?',
        subtitle: 'Nothing is saved until you publish it.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DcButton(
              'Keep editing',
              variant: DcButtonVariant.outline,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
            const SizedBox(height: Space.sm),
            DcButton(
              'Discard',
              variant: DcButtonVariant.danger,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    );
    if (discard ?? false) navigator.maybePop();
  }

  @override
  void dispose() {
    _page.dispose();
    _title.dispose();
    _tagline.dispose();
    _description.dispose();
    _hostNote.dispose();
    super.dispose();
  }

  // ── Chrome ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final created = _createdId;
    if (created != null) {
      return _PublishedView(
        eventId: created,
        onView: () => Go.dinner(context, created),
        onDone: () => Navigator.of(context).maybePop(),
      );
    }

    return Scaffold(
      backgroundColor: dc.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _RoomStep(this),
                  _DetailsStep(this),
                  _MenuStep(this),
                  _PriceStep(this),
                ],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final dc = context.dc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcIconButton(
                Icons.close_rounded,
                variant: DcIconButtonVariant.surface,
                size: 42,
                iconSize: 20,
                tooltip: 'Close',
                onPressed: _confirmClose,
              ),
              const Spacer(),
              DcTag(
                'Step ${_step + 1} of $_stepCount',
                tone: PillTone.accent,
                size: DcTagSize.small,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              for (var i = 0; i < _stepCount; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == _stepCount - 1 ? 0 : 5,
                    ),
                    child: AnimatedContainer(
                      duration: Motion.base,
                      curve: Motion.enter,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step ? dc.accent : dc.surfaceSunken,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Text(
            _eyebrows[_step].toUpperCase(),
            style: AppType.overline(color: dc.accent),
          ),
          const SizedBox(height: Space.sm),
          Text(
            _titles[_step],
            style: AppType.serif(
              27,
              weight: 560,
              height: 1.12,
              tracking: -0.9,
              color: dc.ink,
            ),
          ),
          const SizedBox(height: Space.xs + 2),
          Text(_notes[_step], style: context.text.bodySmall),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final dc = context.dc;
    final note = _blockNote;

    return DcBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: dc.inkFaint),
                const SizedBox(width: 6),
                Expanded(child: Text(note, style: context.text.bodySmall)),
              ],
            ),
            const SizedBox(height: Space.md),
          ],
          Row(
            children: [
              if (_step > 0) ...[
                DcButton(
                  'Back',
                  variant: DcButtonVariant.outline,
                  expand: false,
                  onPressed: _back,
                ),
                const SizedBox(width: Space.sm),
              ],
              Expanded(
                child: DcButton(
                  _isLast ? 'Publish table' : 'Continue',
                  enabled: _canAdvance,
                  icon: _isLast ? Icons.check_rounded : null,
                  trailingIcon: _isLast ? null : Icons.arrow_forward_rounded,
                  onPressed: _isLast ? _publish : _next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The publish button also needs a venue, which the last step does not ask
  /// for again — so it mirrors the first step's requirement.
  bool get _canAdvance => _canContinue && _venue != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — the room
// ─────────────────────────────────────────────────────────────────────────────

class _RoomStep extends StatelessWidget {
  const _RoomStep(this.host);

  final _CreateDinnerScreenState host;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final venues = [...app.allVenues]
      ..sort((a, b) {
        if (a.isPartner != b.isPartner) return a.isPartner ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xxl,
      ),
      children: [
        _FieldLabel(
          'Choose a room',
          trailing: '${app.partnerVenues.length} partner rooms',
        ),
        for (var i = 0; i < venues.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : Space.sm),
            child: _VenueTile(
              venue: venues[i],
              selected: host._venue?.id == venues[i].id,
              onTap: () => host._selectVenue(venues[i]),
            ),
          ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Cover photo', trailing: '${_coverPool.length} ready'),
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _coverPool.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (context, index) {
              final asset = _coverPool[index];
              return _CoverTile(
                asset: asset,
                selected: host._cover == asset,
                onTap: () => host._selectCover(asset),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VenueTile extends StatelessWidget {
  const _VenueTile({
    required this.venue,
    required this.selected,
    required this.onTap,
  });

  final Restaurant venue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Material(
      color: dc.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: dc.accent.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: selected ? dc.accent : dc.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: DcImage(venue.heroAsset, width: 52, height: 52),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            venue.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall,
                          ),
                        ),
                        if (venue.isPartner) ...[
                          const SizedBox(width: Space.sm),
                          const DcTag(
                            'Partner',
                            icon: Icons.storefront_rounded,
                            tone: PillTone.pine,
                            size: DcTagSize.small,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${venue.cuisine} · ${venue.neighborhood}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        RatingPill(rating: venue.rating, compact: true),
                        const SizedBox(width: Space.sm),
                        Text('·', style: context.text.bodySmall),
                        const SizedBox(width: Space.sm),
                        Text(
                          venue.priceLevelLabel,
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(width: Space.sm),
                        Text('·', style: context.text.bodySmall),
                        const SizedBox(width: Space.sm),
                        Flexible(
                          child: Text(
                            Fmt.distance(venue.distanceMeters),
                            style: context.text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 21,
                color: selected ? dc.accent : dc.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.enter,
        width: 108,
        padding: EdgeInsets.all(selected ? 2.5 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? dc.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DcImage(asset, radius: Radii.sm),
            if (selected)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: dc.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — the table
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep(this.host);

  final _CreateDinnerScreenState host;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final days = [
      for (var i = 0; i < 21; i++) _CreateDinnerScreenState._dayOffset(i),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xxl,
      ),
      children: [
        DcTextField(
          controller: host._title,
          label: 'Title',
          hint: 'Dinner at Maison Lumen',
          textInputAction: TextInputAction.next,
          onChanged: host._onTitleChanged,
        ),
        const SizedBox(height: Space.lg),
        DcTextField(
          controller: host._tagline,
          label: 'One-liner',
          hint: 'The line that makes people want a seat',
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Kind of table'),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final type in ExperienceType.values)
              DcTag(
                type.label,
                icon: type.icon,
                size: DcTagSize.large,
                selected: host._type == type,
                onTap: () => host._selectType(type),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Date', trailing: Fmt.until(host._start)),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (context, index) => _DayTile(
              day: days[index],
              selected: _sameDay(days[index], host._day),
              onTap: () => host._selectDay(days[index]),
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Start time', trailing: Fmt.clock(host._start)),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final slot in _timeSlots)
              DcTag(
                Fmt.clock(DateTime(2000, 1, 1, slot.$1, slot.$2)),
                size: DcTagSize.medium,
                selected: host._hour == slot.$1 && host._minute == slot.$2,
                onTap: () => host._selectTime(slot.$1, slot.$2),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('How long'),
        DcSegmented<int>(
          value: host._duration,
          onChanged: host._selectDuration,
          segments: [
            for (final minutes in _durations)
              DcSegment(minutes, Fmt.duration(minutes)),
          ],
        ),
        const SizedBox(height: Space.xl),
        DcSurface(
          radius: Radii.lg,
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.md,
            Space.md,
          ),
          child: DcStepper(
            value: host._seats,
            min: 2,
            max: 16,
            onChanged: host._setSeats,
            label: 'Seats at the table',
            suffix: host._seats == 16
                ? '16 seats · the whole room'
                : '${host._seats} seats',
          ),
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Who can see it', trailing: host._audience.label),
        Column(
          children: [
            for (final audience in Audience.values)
              Padding(
                padding: EdgeInsets.only(
                  top: audience == Audience.public ? 0 : Space.sm,
                ),
                child: _AudienceTile(
                  audience: audience,
                  selected: host._audience == audience,
                  onTap: () => host._selectAudience(audience),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: dc.inkFaint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Only public tables appear on Discover. The rest are shared '
                'with a link you control.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final fg = selected ? dc.canvas : dc.ink;
    final sub = selected ? dc.canvas.withValues(alpha: 0.72) : dc.inkFaint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.enter,
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        decoration: BoxDecoration(
          color: selected ? dc.ink : dc.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? dc.ink : dc.line, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Fmt.weekday(day).toUpperCase(),
              style: AppType.sans(
                9.5,
                weight: 640,
                height: 1,
                tracking: 0.6,
                color: sub,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${day.day}',
              style: AppType.serif(
                19,
                weight: 600,
                height: 1,
                tracking: -0.4,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Fmt.monthTag(day),
              style: AppType.sans(
                9.5,
                weight: 560,
                height: 1,
                tracking: 0.4,
                color: sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceTile extends StatelessWidget {
  const _AudienceTile({
    required this.audience,
    required this.selected,
    required this.onTap,
  });

  final Audience audience;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Material(
      color: selected ? dc.accentSoft : dc.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: selected ? dc.accent : dc.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                audience.icon,
                size: 19,
                color: selected ? dc.accent : dc.inkMuted,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(audience.label, style: context.text.titleSmall),
                    const SizedBox(height: 2),
                    Text(audience.hint, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? dc.accent : dc.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

/// Overline label that opens a block of controls, with an optional right-hand
/// note such as a count or the current selection.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppType.overline(color: dc.inkFaint),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppType.sans(
                11.5,
                weight: 560,
                tracking: 0.2,
                color: dc.inkFaint,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — the menu
// ─────────────────────────────────────────────────────────────────────────────

class _MenuStep extends StatelessWidget {
  const _MenuStep(this.host);

  final _CreateDinnerScreenState host;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xxl,
      ),
      children: [
        _FieldLabel('How it is served', trailing: host._menuStyle.label),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final style in MenuStyle.values)
              DcTag(
                style.label,
                size: DcTagSize.large,
                selected: host._menuStyle == style,
                onTap: () => host._selectMenuStyle(style),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: _FieldLabel('Courses')),
            DcTag(
              'Use a template',
              icon: Icons.auto_awesome_rounded,
              tone: PillTone.accent,
              size: DcTagSize.small,
              onTap: host._useTemplate,
            ),
          ],
        ),
        if (host._courses.isEmpty)
          DcSurface(
            radius: Radii.lg,
            color: dc.surfaceAlt,
            showBorder: false,
            child: DcEmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'No courses yet',
              message:
                  'Templates follow the kind of table you picked. Rewrite them '
                  'afterwards — the wording is yours.',
              actionLabel: 'Start from a template',
              onAction: host._useTemplate,
              compact: true,
            ),
          )
        else
          for (var i = 0; i < host._courses.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.sm),
              child: _CourseCard(
                index: i,
                item: host._courses[i],
                onEdit: () => _editCourse(context, host, i),
                onRemove: () => host._removeCourse(i),
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: DcButton(
            'Add a course',
            variant: DcButtonVariant.outline,
            size: DcButtonSize.medium,
            icon: Icons.add_rounded,
            onPressed: () => _editCourse(context, host, null),
          ),
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel(
          'Included in the price',
          trailing: '${host._included.length} selected',
        ),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final item in _includedPool)
              DcTag(
                item,
                size: DcTagSize.medium,
                icon: host._included.contains(item)
                    ? Icons.check_rounded
                    : null,
                selected: host._included.contains(item),
                onTap: () => host._toggleIncluded(item),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _FieldLabel('Vibe', trailing: '${host._vibes.length} tags'),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final tag in _vibePool)
              DcTag(
                tag,
                size: DcTagSize.medium,
                selected: host._vibes.contains(tag),
                onTap: () => host._toggleVibe(tag),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        DcTextField(
          controller: host._description,
          label: 'Description',
          hint: 'How the evening runs — the part guests cannot guess from the menu.',
          maxLines: 5,
        ),
        const SizedBox(height: Space.lg),
        DcTextField(
          controller: host._hostNote,
          label: 'A note from you',
          hint: 'Why you are hosting this one. Guests read it before booking.',
          maxLines: 2,
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.index,
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return DcSurface(
      radius: Radii.md,
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.sm,
        Space.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: dc.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppType.sans(
                  12,
                  weight: 700,
                  height: 1,
                  color: dc.isDark ? dc.accent : AppColors.clay700,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                    if (item.isSignature) ...[
                      const SizedBox(width: Space.sm),
                      const DcTag(
                        'Signature',
                        icon: Icons.star_rounded,
                        tone: PillTone.gold,
                        size: DcTagSize.small,
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
                if (item.pairing != null) ...[
                  const SizedBox(height: 6),
                  MetaPill(item.pairing!, icon: Icons.wine_bar_rounded),
                ],
              ],
            ),
          ),
          DcIconButton(
            Icons.edit_outlined,
            variant: DcIconButtonVariant.plain,
            size: 34,
            iconSize: 17,
            tooltip: 'Edit course',
            onPressed: onEdit,
          ),
          DcIconButton(
            Icons.delete_outline_rounded,
            variant: DcIconButtonVariant.plain,
            size: 34,
            iconSize: 17,
            color: dc.danger,
            tooltip: 'Remove course',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

Future<void> _editCourse(
  BuildContext context,
  _CreateDinnerScreenState host,
  int? index,
) async {
  final result = await CourseSheet.show(
    context,
    initial: index == null ? null : host._courses[index],
    type: host._type,
  );
  if (result == null) return;
  if (index == null) {
    host._addCourse(result);
  } else {
    host._replaceCourse(index, result);
  }
}

/// Editor for a single course: the dish, how it is described and whether it is
/// the course the host is known for.
class CourseSheet extends StatefulWidget {
  const CourseSheet({super.key, this.initial, required this.type});

  final MenuItem? initial;
  final ExperienceType type;

  static Future<MenuItem?> show(
    BuildContext context, {
    MenuItem? initial,
    required ExperienceType type,
  }) {
    return DcSheet.show<MenuItem>(
      context,
      builder: (_) => CourseSheet(initial: initial, type: type),
    );
  }

  @override
  State<CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<CourseSheet> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _body = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final _pairing = TextEditingController(
    text: widget.initial?.pairing ?? '',
  );
  late bool _signature = widget.initial?.isSignature ?? false;

  bool get _valid => _name.text.trim().isNotEmpty;

  void _save() {
    final pairing = _pairing.text.trim();
    Navigator.of(context).pop(
      MenuItem(
        name: _name.text.trim(),
        description: _body.text.trim(),
        pairing: pairing.isEmpty ? null : pairing,
        isSignature: _signature,
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    _pairing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adding = widget.initial == null;

    return DcSheet(
      title: adding ? 'Add a course' : 'Edit course',
      subtitle: '${widget.type.label} · guests see this on the table page',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DcTextField(
              controller: _name,
              label: 'Dish',
              hint: 'Grilled octopus, smoked paprika',
              autofocus: adding,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.lg),
            DcTextField(
              controller: _body,
              label: 'What it is',
              hint: 'Two lines a guest can picture',
              maxLines: 2,
            ),
            const SizedBox(height: Space.lg),
            DcTextField(
              controller: _pairing,
              label: 'Pairing (optional)',
              hint: 'A glass of something cold',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: Space.md),
            DcSwitchRow(
              title: 'Signature course',
              subtitle: 'Highlighted on the table page',
              icon: Icons.star_outline_rounded,
              value: _signature,
              onChanged: (value) => setState(() => _signature = value),
            ),
            const SizedBox(height: Space.lg),
            DcButton(
              adding ? 'Add to the menu' : 'Save course',
              enabled: _valid,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — the price
// ─────────────────────────────────────────────────────────────────────────────

class _PriceStep extends StatelessWidget {
  const _PriceStep(this.host);

  final _CreateDinnerScreenState host;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final venue = host._venue;
    final start = host._start;

    final base = venue == null ? 58.0 : app.suggestedPrice(venue);
    final gross = host._seats * host._price;
    final fee = gross * 0.08;
    final net = gross - fee;

    final presets = <double>{
      (base * 0.8).roundToDouble(),
      base,
      (base * 1.35).roundToDouble(),
    }.toList()..sort();

    final band = host._price > base * 1.2
        ? 'Top of the range for this room'
        : host._price < base * 0.8
        ? 'Below what this room usually asks'
        : 'In line with this room';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xxl,
      ),
      children: [
        Center(
          child: Column(
            children: [
              Text('Per seat', style: AppType.overline(color: dc.inkFaint)),
              const SizedBox(height: Space.sm),
              Text(
                Fmt.money(host._price),
                style: AppType.serif(
                  46,
                  weight: 580,
                  height: 1.05,
                  tracking: -1.8,
                  color: dc.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(band, style: context.text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        Slider(
          value: host._price.clamp(15, 220),
          min: 15,
          max: 220,
          divisions: 205,
          label: Fmt.money(host._price),
          onChanged: host._setPrice,
        ),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.sm,
            children: [
              for (final preset in presets)
                DcTag(
                  Fmt.money(preset),
                  size: DcTagSize.medium,
                  selected: host._price == preset,
                  onTap: () => host._setPrice(preset),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        DcSurface(
          radius: Radii.lg,
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.xs,
            Space.lg,
            Space.lg,
          ),
          child: Column(
            children: [
              DcKeyValue(
                label: '${host._seats} seats × ${Fmt.money(host._price)}',
                value: Fmt.money(gross),
                icon: Icons.groups_rounded,
              ),
              DcKeyValue(
                label: 'DineCircle fee · 8%',
                value: '-${Fmt.money(fee)}',
                icon: Icons.percent_rounded,
                divider: true,
              ),
              DcKeyValue(
                label: 'You keep',
                value: Fmt.money(net),
                icon: Icons.savings_outlined,
                divider: true,
                emphasis: true,
                valueColor: dc.pine,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: dc.inkFaint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'If every seat sells. Payouts are sent on '
                '${Fmt.dayMonth(app.nextPayoutDate)}.',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xxl),
        _FieldLabel('The table so far', trailing: Fmt.until(start)),
        DcSurface(
          radius: Radii.lg,
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.storefront_rounded,
                label: 'Room',
                value: venue?.name ?? '—',
              ),
              _SummaryRow(
                icon: Icons.event_rounded,
                label: 'When',
                value:
                    '${Fmt.weekday(start)}, ${Fmt.dayMonth(start)} · '
                    '${Fmt.clock(start)}',
                divider: true,
              ),
              _SummaryRow(
                icon: Icons.timelapse_rounded,
                label: 'Runs for',
                value: Fmt.duration(host._duration),
                divider: true,
              ),
              _SummaryRow(
                icon: Icons.group_outlined,
                label: 'Seats',
                value: '${host._seats}',
                divider: true,
              ),
              _SummaryRow(
                icon: Icons.restaurant_menu_rounded,
                label: 'Menu',
                value:
                    '${host._menuStyle.label} · ${host._courses.length} '
                    '${host._courses.length == 1 ? 'course' : 'courses'}',
                divider: true,
              ),
              _SummaryRow(
                icon: Icons.visibility_outlined,
                label: 'Visible to',
                value: host._audience.label,
                divider: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation
// ─────────────────────────────────────────────────────────────────────────────

class _PublishedView extends StatelessWidget {
  const _PublishedView({
    required this.eventId,
    required this.onView,
    required this.onDone,
  });

  final String eventId;
  final VoidCallback onView;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final app = context.app;
    final event = app.event(eventId);
    final venue = app.restaurantFor(event);
    final net = event.seatsTotal * event.pricePerSeat * 0.92;

    return Scaffold(
      backgroundColor: dc.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.xxl,
                  Space.gutter,
                  Space.xxl,
                ),
                children: [
                  const Center(child: _PublishedMedallion()),
                  const SizedBox(height: Space.xl),
                  Text(
                    'Your table is live',
                    textAlign: TextAlign.center,
                    style: AppType.serif(
                      27,
                      weight: 560,
                      height: 1.12,
                      tracking: -0.9,
                      color: dc.ink,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    '${event.seatsTotal} seats at ${venue.name} · '
                    '${Fmt.until(event.start)}',
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: Space.xxl),
                  DinnerCardHero(
                    event: event,
                    height: 330,
                    saved: app.isSaved(event.id),
                    onToggleSave: () => app.toggleSaved(event.id),
                    onTap: onView,
                  ),
                  const SizedBox(height: Space.xl),
                  Center(
                    child: Text(
                      'This is exactly what guests see.',
                      style: AppType.sans(12, weight: 520, color: dc.inkFaint),
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  DcSurface(
                    radius: Radii.lg,
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Column(
                      children: [
                        const _SummaryRow(
                          icon: Icons.ios_share_rounded,
                          label: 'Share the link',
                          value: 'Guests book in two taps',
                        ),
                        const _SummaryRow(
                          icon: Icons.credit_card_rounded,
                          label: 'Payment',
                          value: 'Held by DineCircle',
                          divider: true,
                        ),
                        _SummaryRow(
                          icon: Icons.savings_outlined,
                          label: 'If it fills',
                          value: '${Fmt.money(net)} to you',
                          valueColor: dc.pine,
                          divider: true,
                        ),
                        _SummaryRow(
                          icon: Icons.event_available_rounded,
                          label: 'Payout',
                          value: Fmt.dayMonth(app.nextPayoutDate),
                          divider: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DcBottomBar(
              child: Row(
                children: [
                  DcButton(
                    'Done',
                    variant: DcButtonVariant.outline,
                    expand: false,
                    onPressed: onDone,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: DcButton(
                      'View your table',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: onView,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishedMedallion extends StatelessWidget {
  const _PublishedMedallion();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.7, end: 1),
      duration: Motion.slow,
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(color: dc.accentSoft, shape: BoxShape.circle),
        child: Center(
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: dc.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dc.accent.withValues(alpha: 0.34),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.check_rounded, size: 36, color: dc.onAccent),
          ),
        ),
      ),
    );
  }
}

/// Icon, label and value on one line — the summary rows shared by the price
/// step and the published confirmation.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.divider = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool divider;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;

    return Column(
      children: [
        if (divider) Divider(color: dc.line, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 16, color: dc.inkFaint),
              const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: Text(label, style: context.text.bodyMedium),
              ),
              const SizedBox(width: Space.md),
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.sans(
                    13.5,
                    weight: 620,
                    height: 1.3,
                    color: valueColor ?? dc.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
