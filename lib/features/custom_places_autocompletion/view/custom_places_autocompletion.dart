import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomPlacesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String apiKey;
  final String hintText;
  final InputDecoration? decoration;
  final Function(PlacePrediction)? onSelected;
  final List<String>? countries;
  final Duration debounceTime;

  const CustomPlacesAutocomplete({
    Key? key,
    required this.controller,
    required this.apiKey,
    this.hintText = "Rechercher une adresse...",
    this.decoration,
    this.onSelected,
    this.countries,
    this.debounceTime = const Duration(milliseconds: 600),
  }) : super(key: key);

  @override
  State<CustomPlacesAutocomplete> createState() =>
      _CustomPlacesAutocompleteState();
}

class _CustomPlacesAutocompleteState extends State<CustomPlacesAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceTime, () {
      if (widget.controller.text.isNotEmpty &&
          widget.controller.text.length > 2) {
        _getPlacePredictions(widget.controller.text);
      } else {
        _removeOverlay();
      }
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    setState(() => _isLoading = true);

    try {
      List<PlacePrediction> predictions = [];

      if (kIsWeb) {
        // Pour Flutter Web, utiliser la méthode JavaScript
        predictions = await _getPlacePredictionsWeb(input);
      } else {
        // Pour mobile, utiliser l'API HTTP directement
        predictions = await _getPlacePredictionsMobile(input);
      }

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });

      if (_predictions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      print('Error getting predictions: $e');
      setState(() => _isLoading = false);
      _removeOverlay();
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

  // Méthode pour Web utilisant une approche différente
  Future<List<PlacePrediction>> _getPlacePredictionsWeb(String input) async {
    // Pour le web, nous devons utiliser une solution différente
    // Option 1: Utiliser votre propre serveur proxy
    // Option 2: Utiliser Firebase Cloud Functions
    // Option 3: Utiliser une API alternative comme Nominatim

    // Exemple avec Nominatim (OpenStreetMap) - gratuit et sans CORS
    final baseUrl = 'https://nominatim.openstreetmap.org/search';
    final params = {
      'q': input,
      'format': 'json',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': widget.countries?.join(',') ?? 'fr',
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'VenteMoi/1.0', // Requis par Nominatim
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data
          .map((item) => PlacePrediction(
                placeId: item['place_id'].toString(),
                description: item['display_name'] ?? '',
                mainText: _extractMainText(item),
                secondaryText: _extractSecondaryText(item),
              ))
          .toList();
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  String _extractMainText(Map<String, dynamic> item) {
    final address = item['address'] ?? {};
    final parts = <String>[];

    if (address['house_number'] != null) parts.add(address['house_number']);
    if (address['road'] != null) parts.add(address['road']);
    if (parts.isEmpty && address['city'] != null) parts.add(address['city']);

    return parts.join(' ');
  }

  String _extractSecondaryText(Map<String, dynamic> item) {
    final address = item['address'] ?? {};
    final parts = <String>[];

    if (address['postcode'] != null) parts.add(address['postcode']);
    if (address['city'] != null) parts.add(address['city']);
    if (address['country'] != null) parts.add(address['country']);

    return parts.join(', ');
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return InkWell(
                        onTap: () {
                          widget.controller.text = prediction.description;
                          widget.controller.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: prediction.description.length),
                          );
                          widget.onSelected?.call(prediction);
                          _removeOverlay();
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: index == _predictions.length - 1 ? 0 : 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prediction.mainText.isNotEmpty
                                          ? prediction.mainText
                                          : prediction.description
                                              .split(',')
                                              .first,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (prediction.secondaryText.isNotEmpty)
                                      Text(
                                        prediction.secondaryText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _predictions = [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: widget.decoration ??
              InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.location_on_outlined),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.clear();
                          _removeOverlay();
                        },
                      )
                    : null,
              ),
        ),
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Recherche via OpenStreetMap',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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
      // Pour le web, utiliser Nominatim
      return _getPlaceDetailsWeb(placeId);
    } else {
      // Pour mobile, utiliser Google
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
