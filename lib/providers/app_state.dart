import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../services/firebase_service.dart';

// Provider pour gérer l'état global de l'application : comptes et transactions
class AppState extends ChangeNotifier {
  // Liste des transactions (cache local)
  List<Transaction> _transactions = [];

  // Map des comptes avec leurs soldes (cache local)
  Map<String, double> _comptesAvecSoldes = {};

  // Subscriptions pour les streams Firebase
  StreamSubscription<List<Transaction>>? _transactionsSubscription;
  StreamSubscription<Map<String, double>>? _comptesSubscription;

  // Flag pour indiquer si les données ont été chargées au moins une fois
  bool _hasLoadedComptes = false;

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  Map<String, double> get comptesAvecSoldes => Map.unmodifiable(_comptesAvecSoldes);
  bool get hasLoadedComptes => _hasLoadedComptes;

  // Initialisation - écoute Firebase
  AppState() {
    _initializeFirebaseListeners();
  }

  void _initializeFirebaseListeners() {
    // Annuler les anciens streams s'ils existent
    _comptesSubscription?.cancel();
    _transactionsSubscription?.cancel();

    // Écouter les changements de comptes
    _comptesSubscription = FirebaseService.getComptesStream().listen((comptes) {
      _comptesAvecSoldes = comptes;
      _hasLoadedComptes = true; // Marquer comme chargé après la première réception
      notifyListeners();
    });

    // Écouter les changements de transactions
    _transactionsSubscription = FirebaseService.getTransactionsStream().listen((transactions) {
      _transactions = transactions;
      notifyListeners();
    });
  }

  // Réinitialiser les listeners (appelé lors du changement d'utilisateur)
  void reinitialize() {
    _initializeFirebaseListeners();
  }

  // Ajouter un compte
  Future<void> ajouterCompte(String nomCompte, double soldeInitial) async {
    await FirebaseService.ajouterCompte(nomCompte, soldeInitial);
    // Les données seront automatiquement mises à jour via le stream
  }

  // Supprimer un compte
  Future<void> supprimerCompte(String nomCompte) async {
    // Ne pas supprimer si c'est le dernier compte
    if (_comptesAvecSoldes.length > 1) {
      await FirebaseService.supprimerCompte(nomCompte);
      // Les données seront automatiquement mises à jour via le stream
    }
  }

  // Ajouter une transaction
  Future<void> ajouterTransaction(Transaction transaction) async {
    await FirebaseService.ajouterTransaction(transaction);
    
    // Mettre à jour le solde du compte localement
    double currentSolde = _comptesAvecSoldes[transaction.compte] ?? 0.0;
    double newSolde;
    
    if (transaction.type == "Dépense") {
      newSolde = currentSolde - transaction.amount;
    } else {
      newSolde = currentSolde + transaction.amount;
    }
    
    await FirebaseService.modifierSoldeCompte(transaction.compte, newSolde);
    // Les données seront automatiquement mises à jour via le stream
  }

  // Modifier une transaction
  Future<void> modifierTransaction(Transaction ancienneTransaction, Transaction nouvelleTransaction) async {
    // Supprimer l'ancienne transaction de Firebase (sans modifier le solde)
    await FirebaseService.supprimerTransaction(ancienneTransaction.id);
    
    // Ajouter la nouvelle transaction à Firebase (sans modifier le solde)
    await FirebaseService.ajouterTransaction(nouvelleTransaction);
    
    // Calculer l'effet net sur le solde
    double currentSolde = _comptesAvecSoldes[ancienneTransaction.compte] ?? 0.0;
    
    // Annuler l'effet de l'ancienne transaction
    if (ancienneTransaction.type == "Dépense") {
      currentSolde += ancienneTransaction.amount;
    } else {
      currentSolde -= ancienneTransaction.amount;
    }
    
    // Appliquer l'effet de la nouvelle transaction
    if (nouvelleTransaction.type == "Dépense") {
      currentSolde -= nouvelleTransaction.amount;
    } else {
      currentSolde += nouvelleTransaction.amount;
    }
    
    // Mettre à jour le solde du compte
    await FirebaseService.modifierSoldeCompte(nouvelleTransaction.compte, currentSolde);
    
    // Si le compte a changé, mettre à jour aussi l'ancien compte
    if (ancienneTransaction.compte != nouvelleTransaction.compte) {
      double ancienSolde = _comptesAvecSoldes[ancienneTransaction.compte] ?? 0.0;
      if (ancienneTransaction.type == "Dépense") {
        ancienSolde += ancienneTransaction.amount;
      } else {
        ancienSolde -= ancienneTransaction.amount;
      }
      await FirebaseService.modifierSoldeCompte(ancienneTransaction.compte, ancienSolde);
    }
  }

  // Supprimer une transaction
  Future<void> supprimerTransaction(String id) async {
    final transaction = _transactions.firstWhere((t) => t.id == id);
    
    // Restaurer le solde
    double currentSolde = _comptesAvecSoldes[transaction.compte] ?? 0.0;
    double newSolde;
    
    if (transaction.type == "Dépense") {
      newSolde = currentSolde + transaction.amount;
    } else {
      newSolde = currentSolde - transaction.amount;
    }
    
    await FirebaseService.modifierSoldeCompte(transaction.compte, newSolde);
    await FirebaseService.supprimerTransaction(id);
    // Les données seront automatiquement mises à jour via le stream
  }

  // Modifier le solde d'un compte
  Future<void> modifierSoldeCompte(String compte, double nouveauSolde) async {
    await FirebaseService.modifierSoldeCompte(compte, nouveauSolde);
    // Les données seront automatiquement mises à jour via le stream
  }

  // Obtenir les transactions par période ET par compte
  List<Transaction> getTransactionsByPeriod(String period, {String? compte, int offset = 0}) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case "Jour":
        final targetDay = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
        startDate = DateTime(targetDay.year, targetDay.month, targetDay.day);
        endDate = startDate.add(Duration(days: 1));
        break;
      case "Semaine":
        final targetDate = now.add(Duration(days: offset * 7));
        startDate = targetDate.subtract(Duration(days: 7));
        endDate = targetDate;
        break;
      case "Mois":
        final targetMonth = DateTime(now.year, now.month + offset, 1);
        startDate = DateTime(targetMonth.year, targetMonth.month, 1);
        endDate = DateTime(targetMonth.year, targetMonth.month + 1, 1);
        break;
      case "Année":
        startDate = DateTime(now.year + offset, 1, 1);
        endDate = DateTime(now.year + offset + 1, 1, 1);
        break;
      default:
        final targetMonth = DateTime(now.year, now.month + offset, 1);
        startDate = DateTime(targetMonth.year, targetMonth.month, 1);
        endDate = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    }

    var filtered = _transactions.where((t) => 
      (t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)) && 
      t.date.isBefore(endDate)
    );
    
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
  Map<String, double> getDepensesParCategorie(String period, {String? compte, int offset = 0}) {
    final transactions = getTransactionsByPeriod(period, compte: compte, offset: offset);
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
  Map<String, double> getRevenusParCategorie(String period, {String? compte, int offset = 0}) {
    final transactions = getTransactionsByPeriod(period, compte: compte, offset: offset);
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
  double getTotalDepenses(String period, {String? compte, int offset = 0}) {
    return getTransactionsByPeriod(period, compte: compte, offset: offset)
        .where((t) => t.type == "Dépense")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Obtenir le total des revenus (avec filtre compte optionnel)
  double getTotalRevenus(String period, {String? compte, int offset = 0}) {
    return getTransactionsByPeriod(period, compte: compte, offset: offset)
        .where((t) => t.type == "Revenu")
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _comptesSubscription?.cancel();
    super.dispose();
  }
}