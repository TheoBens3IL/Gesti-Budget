import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'models/transaction.dart';
import 'ajouter_transaction.dart';
import 'liste_transactions.dart';
import 'utils/dialogs.dart';
import 'convertisseur_devises.dart';
import 'widgets/graphiques.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const GestiBudgetApp(),
    ),
  );
}

class GestiBudgetApp extends StatelessWidget {
  const GestiBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestiBudget',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedPeriod = "Mois";
  String compte = "Compte principal";

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    // Récupérer les catégories filtrées par compte
    final categoriesDepenses = appState.getDepensesParCategorie(selectedPeriod, compte: compte);
    final categoriesRevenus = appState.getRevenusParCategorie(selectedPeriod, compte: compte);
    
    final totalDepenses = appState.getTotalDepenses(selectedPeriod, compte: compte);
    final totalRevenus = appState.getTotalRevenus(selectedPeriod, compte: compte);
    
    final solde = appState.comptesAvecSoldes[compte] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Color(0xFF1A0F2E),
              builder: (context) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.currency_exchange, color: Colors.white),
                        title: Text("Convertisseur de devises", style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ConvertisseurDevisesPage()),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        title: HeaderCompte(
          compte: compte,
          solde: solde,
          comptesAvecSoldes: appState.comptesAvecSoldes,
          onCompteChanged: (newCompte) {
            setState(() {
              compte = newCompte!;
            });
          },
          onEditSolde: () => CompteDialogs.modifierSolde(context, compte),
          onAddCompte: () => CompteDialogs.ajouterCompte(context, (nomCompte) {
            setState(() {
              compte = nomCompte;
            });
          }),
          onDeleteCompte: (compteToDelete) {
            CompteDialogs.supprimerCompte(context, compteToDelete, () {
              // Si on supprime le compte actuel, basculer sur le premier compte disponible
              if (compte == compteToDelete) {
                setState(() {
                  compte = appState.comptesAvecSoldes.keys.first;
                });
              }
            });
          },
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Commenté - Sélecteur Dépense/Revenu
                // Container(
                //   decoration: BoxDecoration(
                //     color: Colors.white.withValues(alpha: 0.1),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(...),
                // ),
                // SizedBox(height: 16),

                // ---------------- Sélecteur de période ----------------
                PeriodeSelector(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                ),
                SizedBox(height: 20),

                // ---------------- Section Graphique ----------------
                GraphiquesCarousel(
                  depenses: categoriesDepenses,
                  revenus: categoriesRevenus,
                  periode: selectedPeriod,
                ),
                SizedBox(height: 10),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AjouterTransactionPage(),
                            ),
                          );
                          if (result != null && mounted) {
                            final transaction = Transaction.fromMap(result);
                            Provider.of<AppState>(context, listen: false).ajouterTransaction(transaction);
                          }
                        },
                        icon: Icon(Icons.add),
                        label: Text("Ajouter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListeTransactionsPage(
                                compteInitial: compte,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.list),
                        label: Text("Voir tout"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // ---------------- Deux colonnes: Dépenses et Revenus ----------------
                Expanded(
                  child: Row(
                    children: [
                      // Colonne Dépenses
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              // En-tête Dépenses
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Dépenses",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "€${totalDepenses.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Liste des catégories de dépenses
                              Expanded(
                                child: categoriesDepenses.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Aucune dépense",
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      )
                                    : ListView(
                                        padding: EdgeInsets.all(8),
                                        children: categoriesDepenses.entries.map((entry) {
                                          double percent = totalDepenses == 0 
                                              ? 0 
                                              : (entry.value / totalDepenses) * 100;
                                          
                                          // Utiliser la même couleur que le graphique
                                          final allCategories = categoriesDepenses.keys.toList();
                                          final categoryColor = getCategoryColor(entry.key, allCategories);
                                          
                                          return Card(
                                            color: Colors.white.withValues(alpha: 0.08),
                                            margin: EdgeInsets.symmetric(vertical: 2),
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration: BoxDecoration(
                                                              color: categoryColor,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            entry.key,
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        "${percent.toStringAsFixed(0)}%",
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "€${entry.value.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      color: categoryColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Colonne Revenus
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              // En-tête Revenus
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Revenus",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "€${totalRevenus.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Liste des catégories de revenus
                              Expanded(
                                child: categoriesRevenus.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Aucun revenu",
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      )
                                    : ListView(
                                        padding: EdgeInsets.all(8),
                                        children: categoriesRevenus.entries.map((entry) {
                                          double percent = totalRevenus == 0 
                                              ? 0 
                                              : (entry.value / totalRevenus) * 100;
                                          
                                          // Utiliser la même couleur que le graphique
                                          final allCategories = categoriesRevenus.keys.toList();
                                          final categoryColor = getCategoryColor(entry.key, allCategories);
                                          
                                          return Card(
                                            color: Colors.white.withValues(alpha: 0.08),
                                            margin: EdgeInsets.symmetric(vertical: 2),
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration: BoxDecoration(
                                                              color: categoryColor,
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            entry.key,
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        "${percent.toStringAsFixed(0)}%",
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "€${entry.value.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      color: categoryColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- HeaderCompte StatelessWidget --------------------
class HeaderCompte extends StatelessWidget {
  final String compte;
  final double solde;
  final Map<String, double> comptesAvecSoldes;
  final ValueChanged<String?> onCompteChanged;
  final VoidCallback onEditSolde;
  final VoidCallback onAddCompte;
  final Function(String) onDeleteCompte;

  const HeaderCompte({
    super.key,
    required this.compte,
    required this.solde,
    required this.comptesAvecSoldes,
    required this.onCompteChanged,
    required this.onEditSolde,
    required this.onAddCompte,
    required this.onDeleteCompte,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CompteDropdownMenu(
          compte: compte,
          comptesAvecSoldes: comptesAvecSoldes,
          onCompteChanged: onCompteChanged,
          onAddCompte: onAddCompte,
          onDeleteCompte: onDeleteCompte,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "€${solde.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: onEditSolde,
              child: Icon(Icons.edit, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------- Menu déroulant de comptes avec option de suppression --------------------
class CompteDropdownMenu extends StatelessWidget {
  final String compte;
  final Map<String, double> comptesAvecSoldes;
  final ValueChanged<String?> onCompteChanged;
  final VoidCallback onAddCompte;
  final Function(String) onDeleteCompte;

  const CompteDropdownMenu({
    super.key,
    required this.compte,
    required this.comptesAvecSoldes,
    required this.onCompteChanged,
    required this.onAddCompte,
    required this.onDeleteCompte,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Color(0xFF1A0F2E),
      offset: Offset(0, 50),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            compte,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
      itemBuilder: (BuildContext context) {
        return [
          // Les comptes existants
          ...comptesAvecSoldes.entries.map((entry) {
            return PopupMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (compte == entry.key)
                          Icon(Icons.check, color: Colors.green, size: 18),
                        if (compte == entry.key)
                          SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "€${entry.value.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (comptesAvecSoldes.length > 1)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () {
                        Navigator.pop(context);
                        onDeleteCompte(entry.key);
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
            );
          }),
          // Séparateur
          PopupMenuDivider(),
          // Option pour ajouter un compte
          PopupMenuItem<String>(
            value: "_add_new_",
            child: Row(
              children: [
                Icon(Icons.add_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  "Ajouter un compte",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ];
      },
      onSelected: (String value) {
        if (value == "_add_new_") {
          onAddCompte();
        } else {
          onCompteChanged(value);
        }
      },
    );
  }
}

// -------------------- Sélecteur de période StatelessWidget --------------------
class PeriodeSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const PeriodeSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ["Jour", "Semaine", "Mois", "Année"].map((period) {
        bool isSelected = selectedPeriod == period;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected 
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            elevation: isSelected ? 4 : 0,
          ),
          onPressed: () => onPeriodChanged(period),
          child: Text(period),
        );
      }).toList(),
    );
  }
}

// -------------------- GraphSection StatelessWidget --------------------
class GraphSection extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onViewAll;

  const GraphSection({
    super.key,
    required this.onAdd,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                "Graphique Dépenses/Revenus",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(Icons.add),
                label: Text("Ajouter"),
              ),
              ElevatedButton.icon(
                onPressed: onViewAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(Icons.list),
                label: Text("Voir tout"),
              ),
            ],
          )
        ],
      ),
    );
  }
}