import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as app_models;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir l'ID de l'utilisateur actuel
  static String? get currentUserId => _auth.currentUser?.uid;

  // ============ COMPTES ============

  // Récupérer tous les comptes de l'utilisateur
  static Stream<Map<String, double>> getComptesStream() {
    if (currentUserId == null) return Stream.value({});

    return _firestore
        .collection('comptes')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      Map<String, double> comptes = {};
      for (var doc in snapshot.docs) {
        comptes[doc['nom']] = (doc['solde'] as num).toDouble();
      }
      return comptes;
    });
  }

  // Ajouter un compte
  static Future<void> ajouterCompte(String nom, double solde) async {
    if (currentUserId == null) return;

    await _firestore.collection('comptes').add({
      'userId': currentUserId,
      'nom': nom,
      'solde': solde,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Modifier le solde d'un compte
  static Future<void> modifierSoldeCompte(String nom, double nouveauSolde) async {
    if (currentUserId == null) return;

    final query = await _firestore
        .collection('comptes')
        .where('userId', isEqualTo: currentUserId)
        .where('nom', isEqualTo: nom)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'solde': nouveauSolde,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Supprimer un compte
  static Future<void> supprimerCompte(String nom) async {
    if (currentUserId == null) return;

    final query = await _firestore
        .collection('comptes')
        .where('userId', isEqualTo: currentUserId)
        .where('nom', isEqualTo: nom)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }

    // Supprimer aussi les transactions associées
    final transactions = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .where('compte', isEqualTo: nom)
        .get();

    for (var doc in transactions.docs) {
      await doc.reference.delete();
    }
  }

  // ============ TRANSACTIONS ============

  // Récupérer toutes les transactions de l'utilisateur
  static Stream<List<app_models.Transaction>> getTransactionsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      List<app_models.Transaction> transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return app_models.Transaction(
          id: doc.id,
          type: data['type'] ?? 'Dépense',
          amount: (data['amount'] as num).toDouble(),
          compte: data['compte'] ?? '',
          categorie: data['categorie'] ?? 'Autre',
          commentaire: data['commentaire'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          devise: data['devise'] ?? 'EUR',
        );
      }).toList();
      
      // Trier par date côté client au lieu de Firestore
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    });
  }

  // Ajouter une transaction
  static Future<void> ajouterTransaction(app_models.Transaction transaction) async {
    if (currentUserId == null) return;

    await _firestore.collection('transactions').add({
      'userId': currentUserId,
      'type': transaction.type,
      'amount': transaction.amount,
      'compte': transaction.compte,
      'categorie': transaction.categorie,
      'commentaire': transaction.commentaire,
      'date': Timestamp.fromDate(transaction.date),
      'devise': transaction.devise,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Supprimer une transaction
  static Future<void> supprimerTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }

  // ============ AUTHENTIFICATION ============

  // Connexion anonyme (pour commencer simplement)
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Inscription avec email/mot de passe
  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Créer le document utilisateur
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Connexion avec email/mot de passe
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Vérifier si l'utilisateur est connecté
  static bool get isSignedIn => _auth.currentUser != null;

  // Stream de l'état de connexion
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}