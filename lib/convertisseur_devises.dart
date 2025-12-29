import 'package:flutter/material.dart';
import 'services/service_taux_de_change.dart';

class ConvertisseurDevisesPage extends StatefulWidget {
  const ConvertisseurDevisesPage({super.key});

  @override
  State<ConvertisseurDevisesPage> createState() => _ConvertisseurDevisesPageState();
}

class _ConvertisseurDevisesPageState extends State<ConvertisseurDevisesPage> {
  final String deviseSource = 'EUR'; // Constante, ne peut plus être changée
  String deviseCible = 'USD';
  TextEditingController montantController = TextEditingController(text: '100');
  double? resultat;
  bool isLoading = false;
  Map<String, double>? tauxDeChange;

  @override
  void initState() {
    super.initState();
    _chargerTaux();
  }

  Future<void> _chargerTaux() async {
    setState(() {
      isLoading = true;
    });

    try {
      final rates = await ExchangeRateService.getExchangeRates(baseCurrency: deviseSource);
      setState(() {
        tauxDeChange = rates;
        isLoading = false;
      });
      _convertir();
    } catch (e) {
      setState(() {
        isLoading = false;
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
    if (tauxDeChange == null) return;
    
    String textValue = montantController.text.replaceAll(',', '.');
    double? montant = double.tryParse(textValue);
    
    if (montant != null) {
      setState(() {
        if (deviseSource == deviseCible) {
          resultat = montant;
        } else if (tauxDeChange!.containsKey(deviseCible)) {
          resultat = montant * tauxDeChange![deviseCible]!;
        } else {
          resultat = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Convertisseur de devises", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _chargerTaux,
          ),
        ],
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
            padding: EdgeInsets.all(16),
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Montant source
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Montant à convertir",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: montantController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "0.00",
                                      hintStyle: TextStyle(color: Colors.white30),
                                    ),
                                    onChanged: (_) => _convertir(),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Devise source fixe (EUR)
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white30),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                    child: Text(
                                      deviseSource,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Icône d'échange (enlevée car on ne peut plus inverser)
                      Center(
                        child: Icon(Icons.arrow_downward, color: Colors.white70, size: 40),
                      ),
                      SizedBox(height: 24),

                      // Résultat
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Montant converti",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    resultat != null ? resultat!.toStringAsFixed(2) : "0.00",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: deviseCible,
                                    dropdownColor: Color(0xFF1A0F2E),
                                    style: TextStyle(color: Colors.white, fontSize: 20),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white30),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: ExchangeRateService.supportedCurrencies
                                        .where((currency) => currency != 'EUR') // Exclure EUR de la liste
                                        .map((currency) {
                                      return DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        deviseCible = value!;
                                      });
                                      _convertir();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Taux de change
                      if (tauxDeChange != null && tauxDeChange!.containsKey(deviseCible))
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "1 $deviseSource = ${tauxDeChange![deviseCible]!.toStringAsFixed(4)} $deviseCible",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 24),

                      // Liste des taux
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tous les taux (base: $deviseSource)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: tauxDeChange?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final currency = tauxDeChange!.keys.elementAt(index);
                                    final rate = tauxDeChange![currency]!;
                                    return Card(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      margin: EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: Text(
                                          ExchangeRateService.getSymbol(currency),
                                          style: TextStyle(color: Colors.white, fontSize: 20),
                                        ),
                                        title: Text(
                                          currency,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: Text(
                                          rate.toStringAsFixed(4),
                                          style: TextStyle(
                                            color: Colors.white,
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
    super.dispose();
  }
}