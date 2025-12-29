import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Couleurs globales pour les catégories (partagées entre graphiques et listes)
const List<Color> categoryColors = [
  Color(0xFFE74C3C), // Rouge
  Color(0xFFE67E22), // Orange
  Color(0xFFF39C12), // Jaune/Orange
  Color(0xFF2ECC71), // Vert
  Color(0xFF3498DB), // Bleu
  Color(0xFF9B59B6), // Violet
  Color(0xFF1ABC9C), // Turquoise
  Color(0xFFE91E63), // Rose
  Color(0xFF34495E), // Gris foncé
  Color(0xFF16A085), // Vert foncé
];

// Fonction pour obtenir la couleur d'une catégorie
Color getCategoryColor(String categorie, List<String> allCategories) {
  final index = allCategories.indexOf(categorie);
  return categoryColors[index % categoryColors.length];
}

// ================ Graphique en ligne (courbe) ================
class GraphiqueLigne extends StatelessWidget {
  final Map<String, double> depenses;
  final Map<String, double> revenus;
  final String periode;

  const GraphiqueLigne({
    super.key,
    required this.depenses,
    required this.revenus,
    required this.periode,
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
            "Évolution sur la période",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
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
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Ligne des dépenses
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 0),
                      FlSpot(1, totalDepenses),
                    ],
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                  // Ligne des revenus
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 0),
                      FlSpot(1, totalRevenus),
                    ],
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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
class GraphiqueCamembert extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final data = afficherDepenses ? depenses : revenus;
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

    data.forEach((categorie, montant) {
      final percent = (montant / total) * 100;
      sections.add(
        PieChartSectionData(
          value: montant,
          title: '${percent.toStringAsFixed(1)}%',
          color: getCategoryColor(categorie, allCategories),
          radius: 60, // Réduit de 70 à 60
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Titre avec plus d'espace
          Container(
            padding: EdgeInsets.only(top: 12, bottom: 16),
            child: Text(
              afficherDepenses ? "Répartition des Dépenses" : "Répartition des Revenus",
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
                  centerSpaceRadius: 30, // Réduit de 35 à 30
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

  const GraphiquesCarousel({
    super.key,
    required this.depenses,
    required this.revenus,
    required this.periode,
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
                      GraphiqueBarres(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                      ),
                      GraphiqueLigne(
                        depenses: widget.depenses,
                        revenus: widget.revenus,
                        periode: widget.periode,
                      ),
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