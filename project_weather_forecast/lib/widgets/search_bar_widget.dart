import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        return Column(
          children: [
            // Search button (collapsed state)
            if (!provider.isSearching)
              GestureDetector(
                onTap: () {
                  provider.toggleSearch();
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tìm kiếm thành phố...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Expanded search bar
            if (provider.isSearching)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Search input
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhập tên thành phố...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF95A5A6),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF4A90E2),
                                  size: 20,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                provider.searchCities(value);
                              },
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  provider.fetchWeatherByCity(value);
                                  provider.toggleSearch();
                                }
                              },
                            ),
                          ),

                          // Voice search button
                          IconButton(
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                            icon: Icon(
                              provider.isListening ? Icons.mic : Icons.mic_none,
                              color: provider.isListening
                                  ? Colors.red
                                  : Color(0xFF4A90E2),
                              size: 20,
                            ),
                            onPressed: () async {
                              if (provider.isListening) {
                                await provider.stopVoiceSearch();
                              } else {
                                await provider.startVoiceSearch();
                                if (provider.searchQuery.isNotEmpty) {
                                  _controller.text = provider.searchQuery;
                                }
                              }
                            },
                          ),

                          // Close button
                          IconButton(
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                            icon: Icon(
                              Icons.close,
                              color: Color(0xFF4A90E2),
                              size: 20,
                            ),
                            onPressed: () {
                              _controller.clear();
                              provider.clearSearch();
                              provider.toggleSearch();
                            },
                          ),
                        ],
                      ),

                      // City suggestions
                      if (provider.citySuggestions.isNotEmpty) ...[
                        Divider(height: 1, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 4),
                        Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: provider.citySuggestions.length,
                            itemBuilder: (context, index) {
                              final city = provider.citySuggestions[index];
                              return InkWell(
                                onTap: () {
                                  _controller.clear();
                                  provider.selectCity(city);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Color(0xFF95A5A6),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          city.displayName,
                                          style: TextStyle(
                                            color: Color(0xFF2C3E50),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
