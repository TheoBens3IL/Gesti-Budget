import 'package:flutter/material.dart';
import 'graphiques.dart';

class CategoriesList extends StatelessWidget {
  final String titre;
  final Color couleur;
  final Map<String, double> categories;
  final double total;
  final bool isRevenu;

  const CategoriesList({
    super.key,
    required this.titre,
    required this.couleur,
    required this.categories,
    required this.total,
    required this.isRevenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "€${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Liste des catégories
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      "Aucun${isRevenu ? '' : 'e'} ${titre.toLowerCase().substring(0, titre.length - 1)}",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.all(8),
                    children: categories.entries.map((entry) {
                      double percent = total == 0 
                          ? 0 
                          : (entry.value / total) * 100;
                      
                      // Utiliser la même couleur que le graphique
                      final allCategories = categories.keys.toList();
                      final categoryColor = getCategoryColor(entry.key, allCategories, isRevenu: isRevenu);
                      
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
    );
  }
}
