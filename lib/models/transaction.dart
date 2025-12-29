class Transaction {
  final String id;
  final String type; // "Dépense" ou "Revenu"
  final double amount;
  final String compte;
  final String categorie;
  final String commentaire;
  final DateTime date;
  final String devise; // Nouveau champ

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.compte,
    required this.categorie,
    required this.commentaire,
    required this.date,
    this.devise = 'EUR', // Par défaut en euros
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: map['type'] ?? 'Dépense',
      amount: (map['amount'] ?? 0.0).toDouble(),
      compte: map['compte'] ?? 'Compte principal',
      categorie: map['categorie'] ?? 'Autre',
      commentaire: map['commentaire'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      devise: map['devise'] ?? 'EUR',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'compte': compte,
      'categorie': categorie,
      'commentaire': commentaire,
      'date': date.toIso8601String(),
      'devise': devise,
    };
  }
}