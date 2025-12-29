import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'providers/app_state.dart';
import 'utils/dialogs.dart';

class ListeTransactionsPage extends StatefulWidget {
  final String compteInitial;

  const ListeTransactionsPage({super.key, required this.compteInitial});

  @override
  State<ListeTransactionsPage> createState() => ListeTransactionsPageState();
}

class ListeTransactionsPageState extends State<ListeTransactionsPage> {
  String selectedPeriod = "Mois";
  late String compteSelectionne;

  @override
  void initState() {
    super.initState();
    compteSelectionne = widget.compteInitial;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final transactions = appState.getTransactionsByPeriod(selectedPeriod, compte: compteSelectionne);
    final solde = appState.comptesAvecSoldes[compteSelectionne] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: IconThemeData(color: Colors.white),
        title: HeaderCompte(
          compte: compteSelectionne,
          solde: solde,
          comptesAvecSoldes: appState.comptesAvecSoldes,
          onCompteChanged: (newCompte) {
            setState(() {
              compteSelectionne = newCompte!;
            });
          },
          onEditSolde: () => CompteDialogs.modifierSolde(context, compteSelectionne),
          onAddCompte: () => CompteDialogs.ajouterCompte(context, (nomCompte) {
            setState(() {
              compteSelectionne = nomCompte;
            });
          }),
          onDeleteCompte: (compteToDelete) {
            CompteDialogs.supprimerCompte(context, compteToDelete, () {
              if (compteSelectionne == compteToDelete) {
                setState(() {
                  compteSelectionne = appState.comptesAvecSoldes.keys.first;
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
                PeriodeSelector(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                ),
                SizedBox(height: 20),
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Text(
                            "Aucune transaction pour le moment",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return Card(
                              color: Colors.white.withValues(alpha: 0.1),
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  transaction.type == "Dépense" 
                                      ? Icons.arrow_downward 
                                      : Icons.arrow_upward,
                                  color: transaction.type == "Dépense" 
                                      ? Colors.red 
                                      : Colors.green,
                                ),
                                title: Text(
                                  transaction.categorie,
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${transaction.date.day}/${transaction.date.month}/${transaction.date.year}",
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    if (transaction.commentaire.isNotEmpty)
                                      Text(
                                        transaction.commentaire,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  "${transaction.type == "Dépense" ? "-" : "+"}€${transaction.amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: transaction.type == "Dépense" 
                                        ? Colors.red 
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
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
