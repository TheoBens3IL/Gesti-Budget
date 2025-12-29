import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class AppState extends ChangeNotifier {
  // Liste des transactions
  final List<Transaction> _transactions = [];

  // Map des comptes avec leurs soldes
  final Map<String, double> _comptesAvecSoldes = {
    "Compte principal": 1250.50,
    "Compte épargne": 3500.00,
    "Compte courant": 850.75,
  };

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  Map<String, double> get comptesAvecSoldes => Map.unmodifiable(_comptesAvecSoldes);

  // Ajouter un compte
  void ajouterCompte(String nomCompte, double soldeInitial) {
    if (!_comptesAvecSoldes.containsKey(nomCompte)) {
      _comptesAvecSoldes[nomCompte] = soldeInitial;
      notifyListeners();
    }
  }

  // Supprimer un compte
  void supprimerCompte(String nomCompte) {
    // Ne pas supprimer si c'est le dernier compte
    if (_comptesAvecSoldes.length > 1) {
      _comptesAvecSoldes.remove(nomCompte);
      // Supprimer aussi toutes les transactions de ce compte
      _transactions.removeWhere((t) => t.compte == nomCompte);
      notifyListeners();
    }
  }

  // Ajouter une transaction
  void ajouterTransaction(Transaction transaction) {
    _transactions.add(transaction);
    
    // Mettre à jour le solde du compte
    if (transaction.type == "Dépense") {
      _comptesAvecSoldes[transaction.compte] = 
          (_comptesAvecSoldes[transaction.compte] ?? 0.0) - transaction.amount;
    } else {
      _comptesAvecSoldes[transaction.compte] = 
          (_comptesAvecSoldes[transaction.compte] ?? 0.0) + transaction.amount;
    }
    
    notifyListeners();
  }

  // Supprimer une transaction
  void supprimerTransaction(String id) {
    final transaction = _transactions.firstWhere((t) => t.id == id);
    
    // Restaurer le solde
    if (transaction.type == "Dépense") {
      _comptesAvecSoldes[transaction.compte] = 
          (_comptesAvecSoldes[transaction.compte] ?? 0.0) + transaction.amount;
    } else {
      _comptesAvecSoldes[transaction.compte] = 
          (_comptesAvecSoldes[transaction.compte] ?? 0.0) - transaction.amount;
    }
    
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Modifier le solde d'un compte
  void modifierSoldeCompte(String compte, double nouveauSolde) {
    _comptesAvecSoldes[compte] = nouveauSolde;
    notifyListeners();
  }

  // Obtenir les transactions par période ET par compte
  List<Transaction> getTransactionsByPeriod(String period, {String? compte}) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case "Jour":
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case "Semaine":
        startDate = now.subtract(Duration(days: 7));
        break;
      case "Mois":
        startDate = DateTime(now.year, now.month, 1);
        break;
      case "Année":
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    var filtered = _transactions.where((t) => t.date.isAfter(startDate));
    
    // Filtrer par compte si spécifié
    if (compte != null) {
      filtered = filtered.where((t) => t.compte == compte);
    }
    
    final result = filtered.toList();
    // Trier du plus récent au plus ancien
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  // Obtenir les dépenses par catégorie (avec filtre compte optionnel)
  Map<String, double> getDepensesParCategorie(String period, {String? compte}) {
    final transactions = getTransactionsByPeriod(period, compte: compte);
    final Map<String, double> categories = {};

    for (var transaction in transactions) {
      if (transaction.type == "Dépense") {
        categories[transaction.categorie] = 
            (categories[transaction.categorie] ?? 0.0) + transaction.amount;
      }
    }

    return categories;
  }

  // Obtenir les revenus par catégorie (avec filtre compte optionnel)
  Map<String, double> getRevenusParCategorie(String period, {String? compte}) {
    final transactions = getTransactionsByPeriod(period, compte: compte);
    final Map<String, double> categories = {};

    for (var transaction in transactions) {
      if (transaction.type == "Revenu") {
        categories[transaction.categorie] = 
            (categories[transaction.categorie] ?? 0.0) + transaction.amount;
      }
    }

    return categories;
  }

  // Obtenir le total des dépenses (avec filtre compte optionnel)
  double getTotalDepenses(String period, {String? compte}) {
    return getTransactionsByPeriod(period, compte: compte)
        .where((t) => t.type == "Dépense")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Obtenir le total des revenus (avec filtre compte optionnel)
  double getTotalRevenus(String period, {String? compte}) {
    return getTransactionsByPeriod(period, compte: compte)
        .where((t) => t.type == "Revenu")
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}