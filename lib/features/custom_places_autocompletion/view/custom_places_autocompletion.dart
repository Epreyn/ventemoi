import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';

class CustomPlacesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String apiKey;
  final String hintText;
  final InputDecoration? decoration;
  final Function(PlacePrediction)? onSelected;
  final List<String>? countries;
  final Duration debounceTime;
  final String? labelText;
  final IconData? iconData;
  final bool? enabled;

  const CustomPlacesAutocomplete({
    Key? key,
    required this.controller,
    required this.apiKey,
    this.hintText = "Rechercher une adresse...",
    this.decoration,
    this.onSelected,
    this.countries,
    this.debounceTime = const Duration(milliseconds: 600),
    this.labelText,
    this.iconData,
    this.enabled,
  }) : super(key: key);

  @override
  State<CustomPlacesAutocomplete> createState() =>
      _CustomPlacesAutocompleteState();
}

class _CustomPlacesAutocompleteState extends State<CustomPlacesAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Délai pour permettre de cliquer sur une suggestion
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceTime, () {
      if (widget.controller.text.isNotEmpty &&
          widget.controller.text.length > 2) {
        _getPlacePredictions(widget.controller.text);
      } else {
        setState(() {
          _predictions = [];
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    setState(() => _isLoading = true);

    try {
      List<PlacePrediction> predictions = [];

      if (kIsWeb) {
        predictions = await _getPlacePredictionsWeb(input);
      } else {
        predictions = await _getPlacePredictionsMobile(input);
      }

      if (mounted) {
        setState(() {
          _predictions = predictions;
          _isLoading = false;
          _showSuggestions = predictions.isNotEmpty && _focusNode.hasFocus;
        });
      }
    } catch (e) {
      print('Error getting predictions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _predictions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  // Méthode pour mobile (Android/iOS)
  Future<List<PlacePrediction>> _getPlacePredictionsMobile(String input) async {
    final baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final params = {
      'input': input,
      'key': widget.apiKey,
      'types': 'address',
      'language': 'fr',
    };

    if (widget.countries != null && widget.countries!.isNotEmpty) {
      params['components'] =
          widget.countries!.map((c) => 'country:$c').join('|');
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['predictions'] as List)
          .map((p) => PlacePrediction.fromJson(p))
          .toList();
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  // Méthode pour Web
  Future<List<PlacePrediction>> _getPlacePredictionsWeb(String input) async {
    try {
      final baseUrl = 'https://nominatim.openstreetmap.org/search';
      final params = {
        'q': input,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': widget.countries?.join(',') ?? 'fr',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      print('Nominatim URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VenteMoi/1.0',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          return data
              .map((item) => PlacePrediction(
                    placeId: item['place_id']?.toString() ?? '',
                    description: item['display_name'] ?? '',
                    mainText: _extractMainText(item),
                    secondaryText: _extractSecondaryText(item),
                  ))
              .toList();
        } else {
          print('No results found for: $input');
          return [];
        }
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to load predictions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _getPlacePredictionsWeb: $e');
      rethrow;
    }
  }

  String _extractMainText(Map<String, dynamic> item) {
    final displayName = item['display_name'] ?? '';
    if (displayName.isNotEmpty) {
      final parts = displayName.split(',');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }

    final address = item['address'] ?? {};
    final parts = <String>[];

    if (address['house_number'] != null) {
      parts.add(address['house_number'].toString());
    }
    if (address['road'] != null) {
      parts.add(address['road'].toString());
    }
    if (parts.isEmpty) {
      if (address['city'] != null) {
        parts.add(address['city'].toString());
      } else if (address['town'] != null) {
        parts.add(address['town'].toString());
      } else if (address['village'] != null) {
        parts.add(address['village'].toString());
      }
    }

    return parts.join(' ').trim();
  }

  String _extractSecondaryText(Map<String, dynamic> item) {
    final displayName = item['display_name'] ?? '';
    if (displayName.isNotEmpty) {
      final parts = displayName.split(',');
      if (parts.length > 1) {
        return parts.sublist(1).join(',').trim();
      }
    }

    final address = item['address'] ?? {};
    final parts = <String>[];

    if (address['postcode'] != null) {
      parts.add(address['postcode'].toString());
    }

    if (address['city'] != null) {
      parts.add(address['city'].toString());
    } else if (address['town'] != null) {
      parts.add(address['town'].toString());
    } else if (address['village'] != null) {
      parts.add(address['village'].toString());
    }

    if (address['state'] != null) {
      parts.add(address['state'].toString());
    }

    if (address['country'] != null) {
      parts.add(address['country'].toString());
    }

    return parts.join(', ').trim();
  }

  void _selectPrediction(PlacePrediction prediction) {
    widget.controller.text = prediction.description;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: prediction.description.length),
    );
    widget.onSelected?.call(prediction);
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
  }

  InputDecoration _getDefaultDecoration() {
    return InputDecoration(
      labelText: widget.labelText ?? widget.hintText,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
      ),
      hintText: widget.hintText,
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 14,
      ),
      prefixIcon: widget.iconData != null
          ? Icon(
              widget.iconData,
              color: CustomTheme.lightScheme().primary,
            )
          : Icon(
              Icons.location_on_outlined,
              color: CustomTheme.lightScheme().primary,
            ),
      suffixIcon: widget.controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey[600],
              ),
              onPressed: () {
                widget.controller.clear();
                setState(() {
                  _predictions = [];
                  _showSuggestions = false;
                });
              },
            )
          : null,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CustomTheme.lightScheme().primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CustomTheme.lightScheme().error,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CustomTheme.lightScheme().error,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: widget.enabled ?? true
          ? Colors.white.withOpacity(0.8)
          : Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: UniquesControllers().data.baseMaxWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ de texte principal avec style unifié
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled ?? true,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled ?? true ? Colors.black87 : Colors.grey[600],
            ),
            decoration: widget.decoration ?? _getDefaultDecoration(),
            onTap: () {
              if (_predictions.isNotEmpty) {
                setState(() => _showSuggestions = true);
              }
            },
          ),

          // Indicateur OpenStreetMap pour le web
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 16.0),
              child: Text(
                'Recherche via OpenStreetMap',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Liste des suggestions avec style moderne
          if (_showSuggestions || _isLoading)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            color: CustomTheme.lightScheme().primary,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : _predictions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun résultat trouvé',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = _predictions[index];
                                final isLast = index == _predictions.length - 1;

                                return InkWell(
                                  onTap: () => _selectPrediction(prediction),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade100,
                                                width: 1,
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            color: CustomTheme.lightScheme()
                                                .primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prediction.mainText.isNotEmpty
                                                    ? prediction.mainText
                                                    : prediction.description
                                                        .split(',')
                                                        .first,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (prediction
                                                  .secondaryText.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 2),
                                                  child: Text(
                                                    prediction.secondaryText,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ),
        ],
      ),
    );
  }
}

// Modèle pour les prédictions
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

// Extension pour obtenir les détails d'un lieu
extension PlaceDetails on CustomPlacesAutocomplete {
  static Future<PlaceDetail?> getPlaceDetails(
      String placeId, String apiKey) async {
    if (kIsWeb) {
      return _getPlaceDetailsWeb(placeId);
    } else {
      return _getPlaceDetailsMobile(placeId, apiKey);
    }
  }

  static Future<PlaceDetail?> _getPlaceDetailsMobile(
      String placeId, String apiKey) async {
    try {
      final baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
      final params = {
        'place_id': placeId,
        'key': apiKey,
        'fields': 'geometry,formatted_address,address_components',
        'language': 'fr',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetail.fromGoogleJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  static Future<PlaceDetail?> _getPlaceDetailsWeb(String placeId) async {
    try {
      final baseUrl = 'https://nominatim.openstreetmap.org/details';
      final params = {
        'place_id': placeId,
        'format': 'json',
        'addressdetails': '1',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'VenteMoi/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetail.fromNominatimJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting place details from Nominatim: $e');
      return null;
    }
  }
}

// Modèle pour les détails d'un lieu
class PlaceDetail {
  final double lat;
  final double lng;
  final String formattedAddress;
  final Map<String, String> addressComponents;

  PlaceDetail({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.addressComponents,
  });

  factory PlaceDetail.fromGoogleJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    final components = <String, String>{};

    for (final component in json['address_components'] ?? []) {
      final types = List<String>.from(component['types'] ?? []);
      final value = component['long_name'] ?? '';

      if (types.contains('street_number')) {
        components['street_number'] = value;
      } else if (types.contains('route')) {
        components['street'] = value;
      } else if (types.contains('locality')) {
        components['city'] = value;
      } else if (types.contains('postal_code')) {
        components['postal_code'] = value;
      } else if (types.contains('country')) {
        components['country'] = value;
      }
    }

    return PlaceDetail(
      lat: location['lat']?.toDouble() ?? 0.0,
      lng: location['lng']?.toDouble() ?? 0.0,
      formattedAddress: json['formatted_address'] ?? '',
      addressComponents: components,
    );
  }

  factory PlaceDetail.fromNominatimJson(Map<String, dynamic> json) {
    final components = <String, String>{};
    final address = json['address'] ?? {};

    components['street_number'] = address['house_number'] ?? '';
    components['street'] = address['road'] ?? '';
    components['city'] =
        address['city'] ?? address['town'] ?? address['village'] ?? '';
    components['postal_code'] = address['postcode'] ?? '';
    components['country'] = address['country'] ?? '';

    return PlaceDetail(
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lng: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      formattedAddress: json['display_name'] ?? '',
      addressComponents: components,
    );
  }
}
