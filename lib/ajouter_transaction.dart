import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'models/transaction.dart' as app_models;

class AjouterTransactionPage extends StatefulWidget {
  final app_models.Transaction? transactionToEdit;
  final String? compteInitial;
  
  const AjouterTransactionPage({super.key, this.transactionToEdit, this.compteInitial});

  @override
  State<AjouterTransactionPage> createState() => _AjouterTransactionPageState();
}

class _AjouterTransactionPageState extends State<AjouterTransactionPage> {
  String typeTransaction = "Dépense";
  String? compteSelectionne;
  String? categorieSelectionnee;
  TextEditingController montantController = TextEditingController();
  TextEditingController commentaireController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final List<String> categoriesDepense = [
    "Alimentation",
    "Transport",
    "Loisir",
    "Santé",
    "Loyer",
    "Virement/Remboursement",
    "Retrait",
    "Autre",
  ];

  final List<String> categoriesRevenu = [
    "Salaire",
    "Virement/Remboursement",
    "Intérêt",
    "CAF",
    "Prime",
    "Autre",
  ];

  @override
  void initState() {
    super.initState();
    // Si on édite une transaction, pré-remplir les champs
    if (widget.transactionToEdit != null) {
      final transaction = widget.transactionToEdit!;
      typeTransaction = transaction.type;
      compteSelectionne = transaction.compte;
      categorieSelectionnee = transaction.categorie;
      montantController.text = transaction.amount.toStringAsFixed(2);
      commentaireController.text = transaction.commentaire;
      selectedDate = transaction.date;
    } else if (widget.compteInitial != null) {
      // Si un compte initial est fourni, le pré-sélectionner
      compteSelectionne = widget.compteInitial;
    }
  }

  List<String> get categories => 
      typeTransaction == "Dépense" ? categoriesDepense : categoriesRevenu;

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des comptes depuis AppState
    final appState = context.watch<AppState>();
    final comptes = appState.comptesAvecSoldes.keys.toList();
    
    // Initialiser compteSelectionne si null
    if (compteSelectionne == null && comptes.isNotEmpty) {
      compteSelectionne = comptes.first;
    }

    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit != null ? "Modifier la transaction" : "Ajouter une transaction",
          style: TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF1A0F2E),
              Color(0xFF0F0A1F),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type de transaction (Dépense/Revenu)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              typeTransaction = "Dépense";
                              // Réinitialiser la catégorie si elle n'existe pas dans la nouvelle liste
                              if (categorieSelectionnee != null && 
                                  !categoriesDepense.contains(categorieSelectionnee)) {
                                categorieSelectionnee = null;
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: typeTransaction == "Dépense"
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Dépense",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: typeTransaction == "Dépense"
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              typeTransaction = "Revenu";
                              // Réinitialiser la catégorie si elle n'existe pas dans la nouvelle liste
                              if (categorieSelectionnee != null && 
                                  !categoriesRevenu.contains(categorieSelectionnee)) {
                                categorieSelectionnee = null;
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: typeTransaction == "Revenu"
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Revenu",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: typeTransaction == "Revenu"
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Montant
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Montant",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      TextField(
                        controller: montantController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Colors.white, fontSize: 24),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                          prefixText: "€ ",
                          prefixStyle: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Sélection du compte
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Compte",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: compteSelectionne,
                        dropdownColor: Color(0xFF1A0F2E),
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: comptes.map((compte) {
                          return DropdownMenuItem(
                            value: compte,
                            child: Text(compte),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            compteSelectionne = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Catégorie
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Catégorie",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          bool isSelected = categorieSelectionnee == cat;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                categorieSelectionnee = cat;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Sélection de la date
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: Colors.white,
                                    onPrimary: Color(0xFF1A0F2E),
                                    surface: Color(0xFF1A0F2E),
                                    onSurface: Colors.white,
                                  ), dialogTheme: DialogThemeData(backgroundColor: Color(0xFF1A0F2E)),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Commentaire
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Commentaire (optionnel)",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: commentaireController,
                        style: TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Ajouter une note...",
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Bouton Ajouter/Modifier
                ElevatedButton(
                  onPressed: () {
                    if (montantController.text.isEmpty || categorieSelectionnee == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Veuillez remplir tous les champs obligatoires"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Remplacer la virgule par un point pour le parsing
                    String textValue = montantController.text.replaceAll(',', '.');
                    double? montant = double.tryParse(textValue);
                    
                    if (montant == null || montant <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Montant invalide"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Si on modifie une transaction existante
                    if (widget.transactionToEdit != null) {
                      // Créer la nouvelle transaction avec les modifications
                      final nouvelleTransaction = {
                        "id": widget.transactionToEdit!.id, // Garder le même ID
                        "type": typeTransaction,
                        "amount": montant,
                        "compte": compteSelectionne,
                        "categorie": categorieSelectionnee,
                        "commentaire": commentaireController.text,
                        "date": selectedDate.toIso8601String(),
                        "devise": widget.transactionToEdit!.devise,
                      };
                      
                      // Retourner les deux transactions (ancienne et nouvelle) pour la modification
                      Navigator.pop(context, {
                        "action": "modify",
                        "old": widget.transactionToEdit,
                        "new": nouvelleTransaction,
                      });
                    } else {
                      // Créer une nouvelle transaction
                      final transaction = {
                        "id": DateTime.now().millisecondsSinceEpoch.toString(),
                        "type": typeTransaction,
                        "amount": montant,
                        "compte": compteSelectionne,
                        "categorie": categorieSelectionnee,
                        "commentaire": commentaireController.text,
                        "date": selectedDate.toIso8601String(),
                        "devise": "EUR",
                      };
                      
                      Navigator.pop(context, transaction);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.transactionToEdit != null ? "Modifier la transaction" : "Ajouter la transaction",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    montantController.dispose();
    commentaireController.dispose();
    super.dispose();
  }
}