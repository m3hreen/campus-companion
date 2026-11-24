import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/campus_location.dart';

// Displays campus locations with search, category filters and saved favourites.
class CampusDirectoryScreen extends StatefulWidget {
  const CampusDirectoryScreen({super.key});

  @override
  State<CampusDirectoryScreen> createState() => _CampusDirectoryScreenState();
}

class _CampusDirectoryScreenState extends State<CampusDirectoryScreen> {
  // --------------------------------------------------
  // SEARCH AND FILTER STATE
  // --------------------------------------------------

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  // Location names identify favourites in the bundled directory.
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    // Release the controller when this screen is removed.
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // FAVOURITES STORAGE
  // --------------------------------------------------

  Future<void> _loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> savedFavorites =
        prefs.getStringList('campus_favorites') ?? [];

    // The screen may have closed while storage was loading.
    if (!mounted) return;

    setState(() {
      _favorites.addAll(savedFavorites);
    });
  }

  Future<void> _toggleFavorite(String name) async {
    // Update the visible heart and favourites filter immediately.
    setState(() {
      if (_favorites.contains(name)) {
        _favorites.remove(name);
      } else {
        _favorites.add(name);
      }
    });

    // Store names so favourites remain available after restarting.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('campus_favorites', _favorites.toList());
  }

  // --------------------------------------------------
  // CAMPUS DIRECTORY DATA
  // --------------------------------------------------

  // Bundled locations remain searchable without an internet connection.
  // Opening Google Maps requires an external application or browser.
  final List<CampusLocation> _locations = [
    CampusLocation(
      name: 'Ontario Tech Library (LIB)',
      description:
          'A multi-floor library with individual and group study spaces.',
      address: 'Ontario Tech Library, 2000 Simcoe St N, Oshawa, ON L1G 0C5',
      category: 'Study',
      icon: Icons.local_library,
    ),
    CampusLocation(
      name: 'Business and IT Building (BIT, formerly UB)',
      description:
          'Academic building with classrooms, lecture halls and study areas.',
      address:
          'Business and Information Technology Building (UB), '
          '20 Founders Dr, Oshawa, ON L1G 0C5',
      category: 'Buildings',
      icon: Icons.business,
    ),
    CampusLocation(
      name: 'Science Building (SCI, formerly UA)',
      description: 'Science classrooms, laboratories and student study spaces.',
      address:
          'Science Building (UA), '
          '31 Avenue of Champions, Oshawa, ON L1G 0C5',
      category: 'Buildings',
      icon: Icons.science,
    ),
    CampusLocation(
      name: 'Shawenjigewining Hall (SHA)',
      description: 'Student services, study areas and student support.',
      address:
          'Shawenjigewining Hall, '
          '40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Buildings',
      icon: Icons.people,
    ),
    CampusLocation(
      name: 'Energy Research Centre (ERC)',
      description: 'Academic building with classrooms and research spaces.',
      address:
          'Energy Research Centre (ERC), '
          '30 Founders Dr, Oshawa, ON L1G 0C8',
      category: 'Buildings',
      icon: Icons.bolt,
    ),
    CampusLocation(
      name: 'Student Learning Centre',
      description:
          'Academic support, peer tutoring and writing support '
          'in Shawenjigewining Hall, 2nd floor',
      address:
          'Shawenjigewining Hall, '
          '40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Services',
      icon: Icons.school,
    ),
    CampusLocation(
      name: 'Hunter’s Kitchen',
      description: 'Food and dining located in the Business and IT Building.',
      address:
          'Business and Information Technology Building (UB), '
          '20 Founders Dr, Oshawa, ON L1G 0C5',
      category: 'Food',
      icon: Icons.restaurant,
    ),
    CampusLocation(
      name: 'Tim Hortons (SHA)',
      description: 'Coffee and refreshments in Shawenjigewining Hall.',
      address:
          'Shawenjigewining Hall, '
          '40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Food',
      icon: Icons.coffee,
    ),
    CampusLocation(
      name: 'Study Spaces',
      description:
          'Private and open individual/group study spaces '
          'in Energy Research Centre.',
      address:
          'Energy Research Centre (ERC), '
          '30 Founders Dr, Oshawa, ON L1G 0C8',
      category: 'Study',
      icon: Icons.local_library,
    ),
  ];

  // --------------------------------------------------
  // COMBINED FILTERING
  // --------------------------------------------------

  List<CampusLocation> get _filteredLocations {
    final String query = _searchController.text.toLowerCase();

    // Build a filtered list without changing the original directory.
    return _locations.where((location) {
      final bool matchesSearch =
          location.name.toLowerCase().contains(query) ||
          location.description.toLowerCase().contains(query) ||
          location.address.toLowerCase().contains(query);

      final bool matchesCategory =
          _selectedCategory == 'All' || location.category == _selectedCategory;

      final bool matchesFavorites =
          !_showFavoritesOnly || _favorites.contains(location.name);

      // A location must match every active filter.
      return matchesSearch && matchesCategory && matchesFavorites;
    }).toList();
  }

  // --------------------------------------------------
  // EXTERNAL MAPS NAVIGATION
  // --------------------------------------------------

  Future<void> _openMaps(CampusLocation location) async {
    // Encode spaces and punctuation before adding the address to the URL.
    final String query = Uri.encodeComponent(location.address);

    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMapsError();
      }
    } catch (_) {
      if (!mounted) return;
      _showMapsError();
    }
  }

  void _showMapsError() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Unable to open Maps.')));
  }

  // --------------------------------------------------
  // BUILD DIRECTORY SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const List<String> categories = [
      'All',
      'Study',
      'Food',
      'Buildings',
      'Services',
    ];

    // Calculate once per build instead of filtering again for each row.
    final List<CampusLocation> visibleLocations = _filteredLocations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Campus Directory',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Find buildings, study spaces, food and services.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Rebuild the list whenever the search text changes.
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search campus locations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal scrolling keeps category choices accessible.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Combine this option with the selected category and search.
              FilterChip(
                label: const Text('Favorites only'),
                avatar: const Icon(Icons.favorite),
                selected: _showFavoritesOnly,
                onSelected: (value) {
                  setState(() {
                    _showFavoritesOnly = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Give the results list the remaining space on the screen.
        Expanded(
          child: visibleLocations.isEmpty
              ? const Center(child: Text('No locations found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visibleLocations.length,
                  itemBuilder: (context, index) {
                    final CampusLocation location = visibleLocations[index];
                    final bool isFavorite = _favorites.contains(location.name);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(location.icon)),
                        title: Text(
                          location.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(location.category),
                            Text(location.address),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: isFavorite
                              ? 'Remove favourite'
                              : 'Save favourite',
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () {
                            _toggleFavorite(location.name);
                          },
                        ),

                        // Pass the selected location and parent callbacks.
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => CampusLocationDetails(
                                location: location,
                                isFavorite: isFavorite,
                                onFavoriteChanged: () {
                                  _toggleFavorite(location.name);
                                },
                                onOpenMaps: () => _openMaps(location),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Campus directory • Locations open in Google Maps',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// Shows one location and sends favourite/Maps actions to the directory.
class CampusLocationDetails extends StatefulWidget {
  const CampusLocationDetails({
    super.key,
    required this.location,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onOpenMaps,
  });

  final CampusLocation location;
  final bool isFavorite;
  final VoidCallback onFavoriteChanged;
  final VoidCallback onOpenMaps;

  @override
  State<CampusLocationDetails> createState() => _CampusLocationDetailsState();
}

class _CampusLocationDetailsState extends State<CampusLocationDetails> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();

    // Start with the favourite status passed from the directory.
    _isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final CampusLocation location = widget.location;

    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove favourite' : 'Save favourite',
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              // Refresh this route's heart and update the parent's saved set.
              setState(() {
                _isFavorite = !_isFavorite;
              });

              widget.onFavoriteChanged();
            },
          ),
        ],
      ),

      // Allow scrolling on small screens and with larger system text.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              location.icon,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              location.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Chip(label: Text(location.category)),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(location.description),
            const SizedBox(height: 24),
            const Text(
              'Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(location.address),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onOpenMaps,
                icon: const Icon(Icons.map),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
