import 'package:flutter/material.dart';
import '../../analytics/pages/analytics_page.dart'; // Make sure this path points to your new page

class InsightsTeaserCard extends StatelessWidget {
  const InsightsTeaserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB); // Your app's brand blue

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          // Smoothly slide over to the Analytics Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.blue.shade100,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // The Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.withOpacity(0.2) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pie_chart_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),

              // The Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Spending Insights',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to see your monthly breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // The Arrow indicating navigation
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}