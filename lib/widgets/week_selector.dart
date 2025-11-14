import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';

class WeekSelector extends StatefulWidget {
  // You might want to pass the current week or a date to this widget
  // final int currentWeek;
  // const WeekSelector({Key? key, required this.currentWeek}) : super(key: key);

  const WeekSelector({super.key});

  @override
  _WeekSelectorState createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  final Color highlightColor = const Color(0xFF7C4DFF);
  final Color normalColor = Colors.grey;
  int _currentWeek = 1;
  int _selectedWeek = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isDataProcessed = false;
  bool _needsScroll = false; // New flag

  @override
  void initState() {
    super.initState();
    // Removed ScrollController listener initialization and initial post-frame callback
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Removed post-frame callback for dependency changes
  }

  // Removed _scrollListener method entirely

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserSessionReady(UserSessionProvider userSession) {
    if (_isDataProcessed || userSession.userData == null) {
      return;
    }

    print(
      '\n========== WEEK SELECTOR: Data Ready - Triggering Calculation ==========',
    );
    _calculateCurrentWeek(userSession);
    _isDataProcessed = true; // Mark as processed here
  }

  void _scrollToWeek(int week) {
    if (!_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent == 0.0) {
      print(
        'ScrollController not ready for week $week. hasClients: ${_scrollController.hasClients}, maxScrollExtent: ${_scrollController.hasClients ? _scrollController.position.maxScrollExtent : 'N/A'}',
      );
      return;
    }

    final itemWidth =
        96.0; // Each week item is 88px wide + 4px margin on each side = 96px total
    final screenWidth = MediaQuery.of(context).size.width;

    final offset = (week - 1) * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    print('\n=== SCROLL TO WEEK DEBUG INFO ===');
    print('Scrolling to week: $week');
    print('Item width: $itemWidth');
    print('Screen width: $screenWidth');
    print('Calculated offset: $offset');
    print('ScrollController hasClients: ${_scrollController.hasClients}');
    print(
      'Max scroll extent: ${_scrollController.hasClients ? _scrollController.position.maxScrollExtent : 'N/A'}',
    );
    print(
      'Current scroll offset: ${_scrollController.hasClients ? _scrollController.position.pixels : 'N/A'}',
    );
    print(
      'Target offset after clamp: ${offset.clamp(0.0, _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0)}',
    );
    print('=== END SCROLL TO WEEK DEBUG INFO ===\n');

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _calculateCurrentWeek(UserSessionProvider userSession) {
    print('\n========== WEEK SELECTOR DEBUG INFO (IMPROVED LOGIC) ==========');
    print('User data present for calculation: ${userSession.userData != null}');
    print('Current _isDataProcessed state: $_isDataProcessed');

    int? resolvedWeek;
    final bool babyBorn = userSession.hasDelivered();

    // If baby is born, always show week 40
    if (babyBorn) {
      resolvedWeek = 40;
      print('Baby is born, setting week to 40');
    } else {
      // Get latest ANC visit for most accurate calculation
      final latestAncVisit = userSession.getLatestAncVisit();
      if (latestAncVisit != null) {
        // Try to get gestation_weeks from visit
        final visitWeeks = latestAncVisit['gestation_weeks'] ??
            latestAncVisit['gestational_age_weeks'] ??
            latestAncVisit['gestational_age'];
        
        if (visitWeeks != null) {
          int? weeks;
          if (visitWeeks is int) {
            weeks = visitWeeks;
          } else if (visitWeeks is String) {
            weeks = int.tryParse(visitWeeks);
          } else if (visitWeeks is num) {
            weeks = visitWeeks.toInt();
          }
          
          if (weeks != null && weeks > 0) {
            // If visit has a visit_date, calculate days since visit and add to gestational age
            final visitDateStr = latestAncVisit['visit_date'];
            if (visitDateStr != null) {
              final visitDate = DateTime.tryParse(visitDateStr.toString());
              if (visitDate != null) {
                final daysSinceVisit = DateTime.now().difference(visitDate).inDays;
                final daysAtVisit = weeks * 7;
                final currentDays = (daysAtVisit + daysSinceVisit).clamp(1, 280);
                resolvedWeek = (currentDays / 7).floor().clamp(1, 40);
                print('Calculated from latest visit: weeks=$weeks, daysSinceVisit=$daysSinceVisit, currentDays=$currentDays, resolvedWeek=$resolvedWeek');
              } else {
                resolvedWeek = weeks.clamp(1, 40);
                print('Using visit weeks without date calculation: $resolvedWeek');
              }
            } else {
              resolvedWeek = weeks.clamp(1, 40);
              print('Using visit weeks (no date): $resolvedWeek');
            }
          }
        }
      }

      // Fallback to getLatestGestationalAge() if visit calculation didn't work
      if (resolvedWeek == null) {
        final latestGestationalAge = userSession.getLatestGestationalAge();
        if (latestGestationalAge != null && latestGestationalAge > 0) {
          resolvedWeek = latestGestationalAge.clamp(1, 40);
          print('Resolved from getLatestGestationalAge(): $resolvedWeek');
        }
      }

      // Fallback to pregnancy.current_gestation_weeks from schema
      if (resolvedWeek == null) {
        final currentPreg = userSession.getCurrentPregnancy();
        if (currentPreg != null &&
            currentPreg['current_gestation_weeks'] != null) {
          final cg = currentPreg['current_gestation_weeks'];
          if (cg is int) {
            resolvedWeek = cg.clamp(1, 40);
          } else if (cg is String) {
            resolvedWeek = (int.tryParse(cg) ?? 1).clamp(1, 40);
          } else if (cg is num) {
            resolvedWeek = cg.toInt().clamp(1, 40);
          }
          print('Resolved from pregnancy.current_gestation_weeks: $resolvedWeek');
        }
      }

      // Fallback to compute from LMP if available
      if (resolvedWeek == null) {
        final lmp = userSession.getLmp();
        if (lmp != null) {
          final diffDays = DateTime.now().difference(lmp).inDays;
          resolvedWeek = (diffDays / 7).floor().clamp(1, 40);
          print('Resolved from LMP: $resolvedWeek');
        }
      }
    }

    // Final fallback to week 1
    resolvedWeek ??= 1;

    setState(() {
      _currentWeek = resolvedWeek!;
      _selectedWeek = _currentWeek;
      print('Final current week set to: $_currentWeek');
      _needsScroll = true;
    });
    print('========== END WEEK SELECTOR DEBUG INFO (IMPROVED LOGIC) ==========');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSessionProvider>(
      builder: (context, userSession, child) {
        // Trigger calculation when userData becomes available and not yet processed
        if (userSession.userData != null && !_isDataProcessed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onUserSessionReady(userSession);
          });
        }

        // Trigger scroll after build if _needsScroll is true
        if (_needsScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Future.microtask(() {
                _scrollToWeek(_currentWeek);
                _needsScroll = false; // Reset flag after scrolling
              });
            }
          });
        }

        List<int> weeks = List.generate(40, (index) => index + 1);

        return Container(
          height: 80,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final week = weeks[index];
              bool isCurrentWeek = week == _currentWeek;
              bool isSelected = week == _selectedWeek;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWeek = week;
                  });
                  // Center the selected week when tapped
                  _scrollToWeek(week);
                },
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        isCurrentWeek
                            ? highlightColor.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? highlightColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'week',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? highlightColor : normalColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        week.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          color: isSelected ? highlightColor : normalColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
