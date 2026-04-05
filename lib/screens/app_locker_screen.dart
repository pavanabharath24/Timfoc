import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:usage_stats_helper/usage_stats_helper.dart';
import '../services/storage_service.dart';
import '../theme/lofi_theme.dart';

class AppLockerScreen extends StatefulWidget {
  const AppLockerScreen({super.key});

  @override
  State<AppLockerScreen> createState() => _AppLockerScreenState();
}

class _AppLockerScreenState extends State<AppLockerScreen> {
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  List<String> _blockedPackages = [];
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _hasUsagePermission = await UsageStatsHelper.checkUsagePermission();
    
    // Load blocked packages from settings box
    _blockedPackages = StorageService.settingsBox.get('blockedApps', defaultValue: <String>[])?.cast<String>() ?? [];

    try {
      _installedApps = await InstalledApps.getInstalledApps();
      // Sort: blocked apps first, then alphabetically
      _installedApps.sort((a, b) {
        final aBlocked = _blockedPackages.contains(a.packageName);
        final bBlocked = _blockedPackages.contains(b.packageName);
        if (aBlocked && !bBlocked) return -1;
        if (!aBlocked && bBlocked) return 1;
        return a.name.compareTo(b.name);
      });
      _filteredApps = List.from(_installedApps);
    } catch (e) {
      debugPrint("Error loading apps: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = List.from(_installedApps);
      } else {
        _filteredApps = _installedApps
            .where((app) =>
                app.name.toLowerCase().contains(query.toLowerCase()) ||
                app.packageName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _toggleBlocked(AppInfo app) async {
    setState(() {
      if (_blockedPackages.contains(app.packageName)) {
        _blockedPackages.remove(app.packageName);
      } else {
        _blockedPackages.add(app.packageName);
      }
    });
    await StorageService.settingsBox.put('blockedApps', _blockedPackages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App Locker', style: TextStyle(color: LofiTheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: LofiTheme.outline),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: LofiTheme.secondary))
        : Column(
            children: [
              if (!_hasUsagePermission)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LofiTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LofiTheme.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: LofiTheme.error),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Usage Access Permission Required',
                              style: TextStyle(color: LofiTheme.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To block distracting apps, Timfoc needs to know when they are opened. Please grant Usage Access in Android Settings.',
                        style: TextStyle(color: LofiTheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: LofiTheme.error, foregroundColor: Colors.white),
                        onPressed: () async {
                          UsageStatsHelper.grantUsagePermission();
                          await Future.delayed(const Duration(seconds: 2));
                          _loadData();
                        },
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Select apps to block during your Focus sessions.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: LofiTheme.onSurfaceVariant),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterApps,
                  style: const TextStyle(color: LofiTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    hintStyle: const TextStyle(color: LofiTheme.outline),
                    prefixIcon: const Icon(Icons.search, color: LofiTheme.outline),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: LofiTheme.outline),
                            onPressed: () {
                              _searchController.clear();
                              _filterApps('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: LofiTheme.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Blocked count
              if (_blockedPackages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LofiTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_blockedPackages.length} blocked',
                          style: theme.textTheme.labelSmall?.copyWith(color: LofiTheme.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    final isBlocked = _blockedPackages.contains(app.packageName);
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      leading: app.icon != null
                        ? Image.memory(app.icon!, width: 40, height: 40)
                        : const Icon(Icons.android, size: 40, color: LofiTheme.outline),
                      title: Text(app.name, style: theme.textTheme.titleMedium),
                      subtitle: Text(app.packageName, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                      trailing: Switch(
                        value: isBlocked,
                        onChanged: (val) => _toggleBlocked(app),
                        activeColor: LofiTheme.error,
                        activeTrackColor: LofiTheme.error.withOpacity(0.3),
                        inactiveThumbColor: LofiTheme.outline,
                        inactiveTrackColor: LofiTheme.surfaceHighest,
                      ),
                      onTap: () => _toggleBlocked(app),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
