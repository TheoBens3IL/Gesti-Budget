import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/service_taux_de_change.dart';

class CompteDialogs {
  static void modifierSolde(BuildContext context, String compte) {
    final appState = Provider.of<AppState>(context, listen: false);
    final soldeActuel = appState.comptesAvecSoldes[compte] ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _ModifierSoldeDialog(
          compte: compte,
          soldeActuel: soldeActuel,
          appState: appState,
        );
      },
    );
  }

  static void ajouterCompte(BuildContext context, Function(String) onCompteAdded) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final appState = Provider.of<AppState>(dialogContext, listen: false);
        return _AjouterCompteDialog(
          appState: appState,
          onCompteAdded: onCompteAdded,
        );
      },
    );
  }

  static void convertirDevise(BuildContext context, double montantEUR) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return _ConvertirDeviseDialog(montantEUR: montantEUR);
      },
    );
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
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
          content: SingleChildScrollView(
            child: Column(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text("Annuler", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                appState.supprimerCompte(compte);
                onCompteDeleted();
                Navigator.pop(dialogContext, true);
                Future.delayed(Duration(milliseconds: 100), () {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text("Compte supprimé"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
              },
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Dialog pour modifier le solde
class _ModifierSoldeDialog extends StatefulWidget {
  final String compte;
  final double soldeActuel;
  final AppState appState;

  const _ModifierSoldeDialog({
    required this.compte,
    required this.soldeActuel,
    required this.appState,
  });

  @override
  State<_ModifierSoldeDialog> createState() => _ModifierSoldeDialogState();
}

class _ModifierSoldeDialogState extends State<_ModifierSoldeDialog> {
  late TextEditingController _soldeController;

  @override
  void initState() {
    super.initState();
    _soldeController = TextEditingController(
      text: widget.soldeActuel.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _soldeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardHeight;
    
    return AlertDialog(
      backgroundColor: Color(0xFF1A0F2E),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Text(
        "Modifier le solde",
        style: TextStyle(color: Colors.white),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.compte,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _soldeController,
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
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text("Annuler", style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            String textValue = _soldeController.text.replaceAll(',', '.');
            double? nouveauSolde = double.tryParse(textValue);
            if (nouveauSolde != null) {
              widget.appState.modifierSoldeCompte(widget.compte, nouveauSolde);
              Navigator.pop(context, true);
            } else {
              Navigator.pop(context, false);
              // Afficher l'erreur après la fermeture
              Future.delayed(Duration(milliseconds: 100), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Montant invalide"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
          },
          child: Text("Valider", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Dialog pour ajouter un compte
class _AjouterCompteDialog extends StatefulWidget {
  final AppState appState;
  final Function(String) onCompteAdded;

  const _AjouterCompteDialog({
    required this.appState,
    required this.onCompteAdded,
  });

  @override
  State<_AjouterCompteDialog> createState() => _AjouterCompteDialogState();
}

class _AjouterCompteDialogState extends State<_AjouterCompteDialog> {
  late TextEditingController _nomCompteController;
  late TextEditingController _soldeController;

  @override
  void initState() {
    super.initState();
    _nomCompteController = TextEditingController();
    _soldeController = TextEditingController(text: "0.00");
  }

  @override
  void dispose() {
    _nomCompteController.dispose();
    _soldeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardHeight;
    
    return AlertDialog(
      backgroundColor: Color(0xFF1A0F2E),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Text(
        "Ajouter un compte",
        style: TextStyle(color: Colors.white),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomCompteController,
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
                controller: _soldeController,
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
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text("Annuler", style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            String nomCompte = _nomCompteController.text.trim();
            String textValue = _soldeController.text.replaceAll(',', '.');
            double? soldeInitial = double.tryParse(textValue);
            
            if (nomCompte.isEmpty) {
              Navigator.pop(context, false);
              Future.delayed(Duration(milliseconds: 100), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Veuillez entrer un nom de compte"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
              return;
            }
            
            if (soldeInitial == null) {
              Navigator.pop(context, false);
              Future.delayed(Duration(milliseconds: 100), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Montant invalide"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
              return;
            }
            
            widget.appState.ajouterCompte(nomCompte, soldeInitial);
            widget.onCompteAdded(nomCompte);
            Navigator.pop(context, true);
          },
          child: Text("Ajouter", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Dialog pour convertir la devise
class _ConvertirDeviseDialog extends StatefulWidget {
  final double montantEUR;

  const _ConvertirDeviseDialog({
    required this.montantEUR,
  });

  @override
  State<_ConvertirDeviseDialog> createState() => _ConvertirDeviseDialogState();
}

class _ConvertirDeviseDialogState extends State<_ConvertirDeviseDialog> {
  String _deviseSelectionnee = 'USD';
  Map<String, double>? _tauxDeChange;
  bool _isLoading = false;
  double? _montantConverti;

  @override
  void initState() {
    super.initState();
    _chargerTaux();
  }

  Future<void> _chargerTaux() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rates = await ExchangeRateService.getExchangeRates(baseCurrency: 'EUR');
      setState(() {
        _tauxDeChange = rates;
        _isLoading = false;
      });
      _convertir();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _convertir() {
    if (_tauxDeChange == null || !_tauxDeChange!.containsKey(_deviseSelectionnee)) {
      setState(() {
        _montantConverti = null;
      });
      return;
    }

    setState(() {
      _montantConverti = widget.montantEUR * _tauxDeChange![_deviseSelectionnee]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardHeight;

    return AlertDialog(
      backgroundColor: Color(0xFF1A0F2E),
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          Icon(Icons.currency_exchange, color: Colors.white70, size: 20),
          SizedBox(width: 8),
          Text(
            "Convertir le solde",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.4,
        ),
        child: _isLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Montant en EUR
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Montant",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            "€${widget.montantEUR.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Sélection de la devise
                    Text(
                      "Convertir en",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _deviseSelectionnee,
                      dropdownColor: Color(0xFF1A0F2E),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      items: ExchangeRateService.supportedCurrencies
                          .where((currency) => currency != 'EUR')
                          .map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Row(
                            children: [
                              Text(
                                ExchangeRateService.getSymbol(currency),
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Text(currency),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _deviseSelectionnee = value!;
                        });
                        _convertir();
                      },
                    ),
                    SizedBox(height: 16),
                    // Résultat
                    if (_montantConverti != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Résultat",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              "${ExchangeRateService.getSymbol(_deviseSelectionnee)}${_montantConverti!.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_tauxDeChange != null && _tauxDeChange!.containsKey(_deviseSelectionnee))
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          "1 EUR = ${_tauxDeChange![_deviseSelectionnee]!.toStringAsFixed(4)} $_deviseSelectionnee",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Fermer", style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}