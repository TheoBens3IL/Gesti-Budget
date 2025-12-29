import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CompteDialogs {
  static void modifierSolde(BuildContext context, String compte) {
    final appState = Provider.of<AppState>(context, listen: false);
    final soldeActuel = appState.comptesAvecSoldes[compte] ?? 0.0;
    
    TextEditingController soldeController = TextEditingController(
      text: soldeActuel.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A0F2E),
          title: Text(
            "Modifier le solde",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                compte,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),
              TextField(
                controller: soldeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixText: "€ ",
                  prefixStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Annuler", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                String textValue = soldeController.text.replaceAll(',', '.');
                double? nouveauSolde = double.tryParse(textValue);
                if (nouveauSolde != null) {
                  appState.modifierSoldeCompte(compte, nouveauSolde);
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Montant invalide"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Valider", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose après la fermeture du dialogue
      soldeController.dispose();
    });
  }

  static void ajouterCompte(BuildContext context, Function(String) onCompteAdded) {
    TextEditingController nomCompteController = TextEditingController();
    TextEditingController soldeController = TextEditingController(text: "0.00");

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A0F2E),
          title: Text(
            "Ajouter un compte",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCompteController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nom du compte",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: soldeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Solde initial",
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixText: "€ ",
                  prefixStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Annuler", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                String nomCompte = nomCompteController.text.trim();
                String textValue = soldeController.text.replaceAll(',', '.');
                double? soldeInitial = double.tryParse(textValue);
                
                if (nomCompte.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Veuillez entrer un nom de compte"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (soldeInitial == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Montant invalide"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Provider.of<AppState>(context, listen: false)
                    .ajouterCompte(nomCompte, soldeInitial);
                onCompteAdded(nomCompte);
                Navigator.pop(dialogContext);
              },
              child: Text("Ajouter", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose après la fermeture du dialogue
      nomCompteController.dispose();
      soldeController.dispose();
    });
  }

  static void supprimerCompte(BuildContext context, String compte, VoidCallback onCompteDeleted) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Vérifier qu'il reste au moins 2 comptes
    if (appState.comptesAvecSoldes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vous devez avoir au moins un compte"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A0F2E),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Supprimer le compte",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Êtes-vous sûr de vouloir supprimer le compte :",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                compte,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "⚠️ Toutes les transactions associées seront également supprimées.",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Annuler", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                appState.supprimerCompte(compte);
                onCompteDeleted();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Compte supprimé"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}