
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campus_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CampusDirectoryScreen extends StatefulWidget {
  const CampusDirectoryScreen({super.key});

  @override
  State<CampusDirectoryScreen> createState() =>
      _CampusDirectoryScreenState();
}

class _CampusDirectoryScreenState
    extends State<CampusDirectoryScreen> {

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFavorites =
        prefs.getStringList('campus_favorites') ?? [];

    if (!mounted) return;

    setState(() {
      _favorites.addAll(savedFavorites);
    });
  }

  Future<void> _toggleFavorite(String name) async {
    setState(() {
      if (_favorites.contains(name)) {
        _favorites.remove(name);
      } else {
        _favorites.add(name);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'campus_favorites',
      _favorites.toList(),
    );
  }

  final List<CampusLocation> _locations = [
    CampusLocation(
      name: 'Ontario Tech Library (LIB)',
      description: 'A multi-floor library with individual and group study spaces.',
      address: 'Ontario Tech Library, 2000 Simcoe St N, Oshawa, ON L1G 0C5',
      category: 'Study',
      icon: Icons.local_library,
    ),
    CampusLocation(
      name: 'Business and IT Building (BIT, formerly UB)',
      description: 'Academic building with classrooms, lecture halls and study areas.',
      address: 'Business and Information Technology Building (UB), 20 Founders Dr, Oshawa, ON L1G 0C5',
      category: 'Buildings',
      icon: Icons.business,
    ),
    CampusLocation(
      name: 'Science Building (SCI, formerly UA)',
      description: 'Science classrooms, laboratories and student study spaces.',
      address: 'Science Building (UA), 31 Avenue of Champions, Oshawa, ON L1G 0C5',
      category: 'Buildings',
      icon: Icons.science,
    ),
    CampusLocation(
      name: 'Shawenjigewining Hall (SHA)',
      description: 'Student services, study areas and student support.',
      address: 'Shawenjigewining Hall, 40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Buildings',
      icon: Icons.people,
    ),
    CampusLocation(
      name: 'Energy Research Centre (ERC)',
      description: 'Academic building with classrooms and research spaces.',
      address: 'Energy Research Centre (ERC), 30 Founders Dr, Oshawa, ON L1G 0C8',
      category: 'Buildings',
      icon: Icons.bolt,
    ),
    CampusLocation(
      name: 'Student Learning Centre',
      description: 'Academic support, peer tutoring and writing support in Shawenjigewining Hall, 2nd floor',
      address: 'Shawenjigewining Hall, 40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Services',
      icon: Icons.school,
    ),
    CampusLocation(
      name: 'Hunter’s Kitchen',
      description: 'Food and dining located in the Business and IT Building.',
      address: 'Business and Information Technology Building (UB), 20 Founders Dr, Oshawa, ON L1G 0C5',
      category: 'Food',
      icon: Icons.restaurant,
    ),
    CampusLocation(
      name: 'Tim Hortons (SHA)',
      description: 'Coffee and refreshments in Shawenjigewining Hall.',
      address: 'Shawenjigewining Hall, 40 Founders Dr, Oshawa, ON L1H 7K4',
      category: 'Food',
      icon: Icons.coffee,
    ),
    CampusLocation(
      name: 'Study Spaces',
      description: 'Private and open individual/group study spaces in Energy Research Centre.',
      address: 'Energy Research Centre (ERC), 30 Founders Dr, Oshawa, ON L1G 0C8',
      category: 'Study',
      icon: Icons.local_library,
    ),
  ];

  List<CampusLocation> get _filteredLocations {
    return _locations.where((location) {
      final query = _searchController.text.toLowerCase();

      final matchesSearch =
          location.name.toLowerCase().contains(query) ||
              location.description.toLowerCase().contains(query) ||
              location.address.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
              location.category == _selectedCategory;

      final matchesFavorites =
          !_showFavoritesOnly ||
              _favorites.contains(location.name);

      return matchesSearch &&
          matchesCategory &&
          matchesFavorites;
    }).toList();
  }

  Future<void> _openMaps(CampusLocation location) async {
    final query = Uri.encodeComponent(location.address);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Maps.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Maps.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Study',
      'Food',
      'Buildings',
      'Services',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Campus Directory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Find buildings, study spaces, food and services.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search campus locations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

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

        Expanded(
          child: _filteredLocations.isEmpty
              ? const Center(
            child: Text('No locations found.'),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            itemCount: _filteredLocations.length,
            itemBuilder: (context, index) {
              final location =
              _filteredLocations[index];

              final isFavorite =
              _favorites.contains(location.name);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(location.icon),
                  ),

                  title: Text(
                    location.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(location.category),
                      Text(location.address),
                    ],
                  ),

                  isThreeLine: true,

                  trailing: IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () {
                      _toggleFavorite(location.name);
                    },
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CampusLocationDetails(
                              location: location,
                              isFavorite: isFavorite,
                              onFavoriteChanged: () {
                                _toggleFavorite(location.name);
                              },
                              onOpenMaps: () =>
                                  _openMaps(location),
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
            'Campus directory • Interactive map coming soon',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}


class CampusLocationDetails extends StatefulWidget {
  final CampusLocation location;
  final bool isFavorite;
  final VoidCallback onFavoriteChanged;
  final VoidCallback onOpenMaps;

  const CampusLocationDetails({
    super.key,
    required this.location,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onOpenMaps,
  });

  @override
  State<CampusLocationDetails> createState() =>
      _CampusLocationDetailsState();
}

class _CampusLocationDetailsState
    extends State<CampusLocationDetails> {

  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;

    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });

              widget.onFavoriteChanged();
            },
          ),
        ],
      ),

      body: Padding(
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
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Chip(label: Text(location.category)),

            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(location.description),

            const SizedBox(height: 24),

            const Text(
              'Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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

