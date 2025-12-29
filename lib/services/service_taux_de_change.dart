import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  
  // Cache pour éviter trop de requêtes
  static Map<String, dynamic>? _cachedRates;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  // Liste des devises principales
  static const List<String> supportedCurrencies = [
    'EUR', // Euro
    'USD', // Dollar américain
    'GBP', // Livre sterling
    'CHF', // Franc suisse
    'JPY', // Yen japonais
    'CAD', // Dollar canadien
    'AUD', // Dollar australien
  ];

  static const Map<String, String> currencySymbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'CHF': 'CHF',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
  };

  // Récupérer les taux de change
  static Future<Map<String, double>> getExchangeRates({String baseCurrency = 'EUR'}) async {
    // Vérifier le cache
    if (_cachedRates != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _extractRates(_cachedRates!);
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedRates = data;
        _lastFetchTime = DateTime.now();
        return _extractRates(data);
      } else {
        throw Exception('Erreur lors de la récupération des taux: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Map<String, double> _extractRates(Map<String, dynamic> data) {
    final rates = data['rates'] as Map<String, dynamic>;
    Map<String, double> result = {};
    
    for (String currency in supportedCurrencies) {
      if (rates.containsKey(currency)) {
        result[currency] = (rates[currency] as num).toDouble();
      }
    }
    
    return result;
  }

  // Convertir un montant d'une devise à une autre
  static Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    final rates = await getExchangeRates(baseCurrency: from);
    if (!rates.containsKey(to)) {
      throw Exception('Devise non supportée: $to');
    }

    return amount * rates[to]!;
  }

  // Obtenir le symbole d'une devise
  static String getSymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }
}