import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class StoreAddressesScreen extends StatefulWidget {
  const StoreAddressesScreen({super.key});

  @override
  State<StoreAddressesScreen> createState() => _StoreAddressesScreenState();
}

class _StoreAddressesScreenState extends State<StoreAddressesScreen> {
  late Future<List<Map<String, dynamic>>> _citiesFuture;
  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  Map<String, dynamic>? _selectedCity;
  List<Map<String, dynamic>> _pickupPoints = [];
  bool _isLoadingPoints = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _citiesFuture = _loadCities();
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCities() async {
    final cities = await ApiService.fetchCities();
    setState(() {
      _allCities = cities;
      _filteredCities = cities;
    });
    return cities;
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _allCities.where((city) {
        final cityName = city['name']?.toString().toLowerCase() ?? '';
        return cityName.contains(query);
      }).toList();
    });
  }

  Future<void> _selectCity(Map<String, dynamic> city) async {
    setState(() {
      _selectedCity = city;
      _isLoadingPoints = true;
      _pickupPoints = [];
    });

    try {
      final cityId = city['id'] as int;
      final points = await ApiService.fetchPickupPoints(cityId: cityId);
      setState(() {
        _pickupPoints = points;
        _isLoadingPoints = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPoints = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки пунктов выдачи: ${toUserMessage(e)}',
            ),
          ),
        );
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedCity = null;
      _pickupPoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Адреса магазинов'),
        actions: _selectedCity != null
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSelection,
                  tooltip: 'Сбросить выбор',
                ),
              ]
            : null,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _citiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ServerErrorView(
              message: 'Ошибка загрузки городов: ${toUserMessage(snapshot.error)}',
              onRetry: () {
                setState(() {
                  _citiesFuture = _loadCities();
                });
              },
            );
          }

          return Column(
            children: [
              // Поиск по городам
              if (_selectedCity == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration:  InputDecoration(
                      hintText: 'Введите город',
                      
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:  BorderRadius.circular(12),
                        
                      ),
                      
       focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.black, // рамка когда В фокусе
          width: 2,
        ),
       )

                    ),
                  ),
                ),

              // Выбранный город
              if (_selectedCity != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color.fromARGB(15, 39, 49, 82),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city, color: Color.fromARGB(255, 240, 9, 9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Пункты выдачи в городе ${_selectedCity!['name']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Список городов или пунктов выдачи
              Expanded(
                child: _selectedCity == null
                    ? _buildCitiesList()
                    : _buildPickupPointsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCitiesList() {
    if (_filteredCities.isEmpty) {
      return const Center(child: Text('Города не найдены'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCities.length,
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        final cityName = city['name']?.toString() ?? '';

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.location_city, color: Color.fromARGB(255, 240, 9, 9),
            ),
            title: Text(
              cityName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectCity(city),
          ),
        );
      },
    );
  }

  Widget _buildPickupPointsList() {
    if (_isLoadingPoints) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pickupPoints.isEmpty) {
      return const Center(child: Text('Пунктов выдачи нет в этом городе'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pickupPoints.length,
      itemBuilder: (context, index) {
        final point = _pickupPoints[index];
        final name = point['name']?.toString() ?? '';
        final address = point['address']?.toString() ?? '';
        final workingHours = point['working_hours']?.toString() ?? '';

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Часы работы: $workingHours',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
