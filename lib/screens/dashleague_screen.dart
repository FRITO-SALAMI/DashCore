import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import '../services/supabase_service.dart';
import '../widget/empty_state_widget.dart';

class DashLeagueScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DashLeagueScreen({super.key, required this.onBack});

  @override
  State<DashLeagueScreen> createState() => _DashLeagueScreenState();
}

class _DashLeagueScreenState extends State<DashLeagueScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final settings = context.read<DashSettingsProvider>();

      // Intentar sincronizar datos propios primero para asegurar presencia en el ranking
      await settings.syncProfileToSupabase();

      final supabase = SupabaseService.instance.client;
      if (supabase == null) return;

      final response = await supabase
          .from('profiles')
          .select('id, username, total_distance, max_speed, driver_level')
          .order('total_distance', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _leaderboard = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        debugPrint('DashLeague: Loaded ${_leaderboard.length} users');
      }
    } catch (e) {
      debugPrint('DashLeague: Error fetching leaderboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DashSettingsProvider>();
    final user = SupabaseService.instance.currentUser;

    final String displayName = user?.userMetadata?['display_name'] ??
                              user?.email?.split('@')[0] ?? 'CONDUCTOR';

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'DASHLEAGUE 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildProfileCard(displayName, settings),
                  const SizedBox(height: 25),
                  const Text(
                    'TOP GLOBAL (TOP 50)',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF00E5FF))))
                  else if (_leaderboard.isEmpty)
                    const EmptyStateWidget(
                      icon: Icons.emoji_events_outlined,
                      title: 'LIGA VACÍA',
                      description: 'Aún no hay competidores en la lista global. ¡Sé el primero!',
                    )
                  else
                    ...List.generate(_leaderboard.length, (index) {
                      final item = _leaderboard[index];
                      String uName = item['username']?.toString() ?? 'PILOTO';
                      if (uName.trim().isEmpty) uName = 'PILOTO';
                      if (uName.length > 15) uName = uName.substring(0, 12) + '...';

                      final bool isMe = item['id'] == user?.id;

                      return _buildLeaderboardItem(
                        index + 1,
                        uName,
                        '${(item['total_distance'] ?? 0).round()} KM',
                        '${(item['max_speed'] ?? 0).round()} KM/H',
                        isMe,
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, DashSettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF13161D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
            child: const Icon(Icons.person_rounded, size: 35, color: Color(0xFF00E5FF)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  settings.driverLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCompact('KM', '${settings.totalDistance.round()}'),
                    const SizedBox(width: 15),
                    _buildStatCompact('MAX', '${settings.maxSpeed.round()}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCompact(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String km, String speed, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.5) : null,
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: isMe ? 16 : 14,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name + (isMe ? ' (TÚ)' : ''),
              style: TextStyle(
                color: isMe ? const Color(0xFF00E5FF) : Colors.white,
                fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                km,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isMe ? FontWeight.w900 : FontWeight.normal,
                ),
              ),
              Text(
                speed,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
