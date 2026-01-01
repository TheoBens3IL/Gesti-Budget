import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Couleurs pour les dépenses (palette chaude très variée)
const List<Color> depenseColors = [
  Color(0xFFFF5252), // Rouge vif
  Color(0xFFFF9800), // Orange 
  Color(0xFFFFEB3B), // Jaune
  Color(0xFFFF4081), // Rose fuchsia
  Color(0xFFD84315), // Rouge-brun
  Color(0xFFFFB300), // Ambre
  Color(0xFFE91E63), // Rose
  Color(0xFFFF6F00), // Orange foncé
  Color(0xFFFFD600), // Jaune citron
  Color(0xFF8D6E63), // Marron
  Color(0xFFFF1744), // Rouge-rose
  Color(0xFFFF6E40), // Orange corail
  Color(0xFFF57C00), // Orange brûlé
  Color(0xFFAD1457), // Rose bordeaux
  Color(0xFFFF9100), // Orange doré
];

// Couleurs pour les revenus (palette froide très variée)
const List<Color> revenuColors = [
  Color(0xFF4CAF50), // Vert
  Color(0xFF2196F3), // Bleu
  Color(0xFF00BCD4), // Cyan
  Color(0xFF009688), // Turquoise/Teal
  Color(0xFF3F51B5), // Indigo
  Color(0xFF00796B), // Vert foncé
  Color(0xFF0097A7), // Cyan foncé
  Color(0xFF1976D2), // Bleu foncé
  Color(0xFF388E3C), // Vert forêt
  Color(0xFF0288D1), // Bleu clair
  Color(0xFF26A69A), // Turquoise clair
  Color(0xFF5C6BC0), // Indigo clair
  Color(0xFF00ACC1), // Cyan vif
  Color(0xFF66BB6A), // Vert clair
  Color(0xFF42A5F5), // Bleu ciel
];

// Fonction pour obtenir la couleur d'une catégorie
Color getCategoryColor(String categorie, List<String> allCategories, {bool isRevenu = false}) {
  final index = allCategories.indexOf(categorie);
  final colors = isRevenu ? revenuColors : depenseColors;
  return colors[index % colors.length];
}

// ================ Graphique en ligne (courbe) ================
class GraphiqueLigne extends StatelessWidget {
  final Map<String, double> depenses;
  final Map<String, double> revenus;
  final String periode;
  final List<dynamic> transactions;

  const GraphiqueLigne({
    super.key,
    required this.depenses,
    required this.revenus,
    required this.periode,
    required this.transactions,
  });

  List<FlSpot> _generateSpots(String type) {
    if (transactions.isEmpty) return [FlSpot(0, 0)];

    // Trier les transactions par date
    final sortedTransactions = List.from(transactions);
    sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

    // Filtrer par type
    final filteredTransactions = sortedTransactions.where((t) => t.type == type).toList();
    
    if (filteredTransactions.isEmpty) return [FlSpot(0, 0)];

    // Calculer les points cumulatifs
    List<FlSpot> spots = [];
    double cumulative = 0.0;
    
    // Déterminer le nombre de points selon la période
    int maxPoints = 0;
    switch (periode) {
      case "Jour":
        maxPoints = 24; // Heures
        break;
      case "Semaine":
        maxPoints = 7; // Jours
        break;
      case "Mois":
        maxPoints = 30; // Jours
        break;
      case "Année":
        maxPoints = 12; // Mois
        break;
      default:
        maxPoints = 30;
    }

    // Créer une carte de sommes par intervalle
    Map<int, double> sumsByInterval = {};
    
    for (var transaction in filteredTransactions) {
      int interval;
      final date = transaction.date;
      
      switch (periode) {
        case "Jour":
          interval = date.hour;
          break;
        case "Semaine":
          interval = date.weekday - 1; // 0-6
          break;
        case "Mois":
          interval = date.day - 1; // 0-29
          break;
        case "Année":
          interval = date.month - 1; // 0-11
          break;
        default:
          interval = date.day - 1;
      }
      
      sumsByInterval[interval] = (sumsByInterval[interval] ?? 0.0) + transaction.amount;
    }

    // Générer les spots cumulatifs
    cumulative = 0.0;
    for (int i = 0; i < maxPoints; i++) {
      cumulative += sumsByInterval[i] ?? 0.0;
      if (cumulative > 0) {
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
    }

    // Si aucun spot n'a été ajouté, retourner un spot à zéro
    if (spots.isEmpty) return [FlSpot(0, 0)];

    return spots;
  }

  String _getBottomTitle(double value, String periode) {
    final intValue = value.toInt();
    switch (periode) {
      case "Jour":
        return "${intValue}h";
      case "Semaine":
        const days = ["L", "M", "M", "J", "V", "S", "D"];
        return intValue < days.length ? days[intValue] : "";
      case "Mois":
        return intValue % 5 == 0 ? "${intValue + 1}" : "";
      case "Année":
        const months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];
        return intValue < months.length ? months[intValue] : "";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsDepenses = _generateSpots("Dépense");
    final spotsRevenus = _generateSpots("Revenu");

    // Trouver le max pour l'échelle
    double maxY = 0;
    for (var spot in [...spotsDepenses, ...spotsRevenus]) {
      if (spot.y > maxY) maxY = spot.y;
    }
    if (maxY == 0) maxY = 100; // Valeur par défaut

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Évolution sur la période",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '€${value.toInt()}',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            _getBottomTitle(value, periode),
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: [
                  // Ligne des dépenses
                  LineChartBarData(
                    spots: spotsDepenses,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: spotsDepenses.length <= 12,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  // Ligne des revenus
                  LineChartBarData(
                    spots: spotsRevenus,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: spotsRevenus.length <= 12,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.red, "Dépenses"),
              SizedBox(width: 20),
              _buildLegend(Colors.green, "Revenus"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// ================ Graphique en barres ================
class GraphiqueBarres extends StatelessWidget {
  final Map<String, double> depenses;
  final Map<String, double> revenus;

  const GraphiqueBarres({
    super.key,
    required this.depenses,
    required this.revenus,
  });

  @override
  Widget build(BuildContext context) {
    final totalDepenses = depenses.values.fold(0.0, (sum, val) => sum + val);
    final totalRevenus = revenus.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Comparaison Dépenses / Revenus",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (totalDepenses > totalRevenus ? totalDepenses : totalRevenus) * 1.2,
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '€${value.toInt()}',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return Text('Dépenses', style: TextStyle(color: Colors.white70, fontSize: 11));
                          case 1:
                            return Text('Revenus', style: TextStyle(color: Colors.white70, fontSize: 11));
                          default:
                            return Text('');
                        }
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalDepenses,
                        color: Colors.red,
                        width: 40,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalRevenus,
                        color: Colors.green,
                        width: 40,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================ Graphique en camembert (Pie Chart) ================
class GraphiqueCamembert extends StatefulWidget {
  final Map<String, double> depenses;
  final Map<String, double> revenus;
  final bool afficherDepenses;

  const GraphiqueCamembert({
    super.key,
    required this.depenses,
    required this.revenus,
    this.afficherDepenses = true,
  });

  @override
  State<GraphiqueCamembert> createState() => _GraphiqueCamembertState();
}

class _GraphiqueCamembertState extends State<GraphiqueCamembert> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.afficherDepenses ? widget.depenses : widget.revenus;
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    if (total == 0) {
      return Center(
        child: Text(
          "Aucune donnée",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final allCategories = data.keys.toList();
    List<PieChartSectionData> sections = [];

    int index = 0;
    data.forEach((categorie, montant) {
      final percent = (montant / total) * 100;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 12.0 : 10.0;
      final radius = isTouched ? 70.0 : 60.0;
      
      sections.add(
        PieChartSectionData(
          value: montant,
          title: isTouched ? categorie : '${percent.toStringAsFixed(1)}%',
          color: getCategoryColor(categorie, allCategories, isRevenu: !widget.afficherDepenses),
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
      index++;
    });

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Titre avec plus d'espace
          Container(
            padding: EdgeInsets.only(top: 12, bottom: 16),
            child: Text(
              widget.afficherDepenses ? "Répartition des Dépenses" : "Répartition des Revenus",
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          // Graphique camembert centré avec padding
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ================ Widget principal avec PageView ================
class GraphiquesCarousel extends StatefulWidget {
  final Map<String, double> depenses;
  final Map<String, double> revenus;
  final String periode;
  final List<dynamic> transactions;

  const GraphiquesCarousel({
    super.key,
    required this.depenses,
    required this.revenus,
    required this.periode,
    required this.transactions,
  });

  @override
  State<GraphiquesCarousel> createState() => _GraphiquesCarouselState();
}

class _GraphiquesCarouselState extends State<GraphiquesCarousel> {
  int currentPage = 0;
  final PageController _pageController = PageController();
  bool _isHovering = false;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    children: [
                      GraphiqueCamembert(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                        afficherDepenses: true,
                      ),
                      GraphiqueCamembert(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                        afficherDepenses: false,
                      ),
                      GraphiqueBarres(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                      ),
                      GraphiqueLigne(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                        periode: widget.periode,
                        transactions: widget.transactions,
                      ),
                    ],
                  ),
                ),
                // Indicateurs de page
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            
            // Flèche gauche
            if (_isHovering && currentPage > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 40,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _goToPage(currentPage - 1),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Flèche droite
            if (_isHovering && currentPage < 3)
              Positioned(
                right: 8,
                top: 0,
                bottom: 40,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _goToPage(currentPage + 1),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}