import 'package:flutter/material.dart';

class AIOutputVisualization extends StatelessWidget {
  final List<int> syllableCount;
  final bool isCorrect;
  final double score;
  final List<String> corpus;

  const AIOutputVisualization({
    required this.syllableCount,
    required this.isCorrect,
    required this.score,
    required this.corpus,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // Ensures it goes back to the previous screen
        return true; // Allows default back navigation
      },
      child: Scaffold(
        // Changed from Material to Scaffold for better structure
        appBar: AppBar(
          title: const Text("AI Output"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Ensures back button behavior
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Syllable Count Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildSyllableCountCard(
                        title: 'Input Syllables',
                        count: syllableCount[0],
                        icon: Icons.text_fields,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSyllableCountCard(
                        title: 'Output Syllables',
                        count: syllableCount[1],
                        icon: Icons.volume_up,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Divider(thickness: 1, color: Colors.grey[300]),

                // Is Correct and Score Section
                _buildInfoRow(
                  icon: Icons.check_circle,
                  color: isCorrect ? Colors.green : Colors.red,
                  title: 'Is Correct',
                  value: isCorrect ? 'Yes' : 'No',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.star,
                  color: Colors.amber,
                  title: 'Score',
                  value: score.toString(),
                ),
                const SizedBox(height: 16),

                Divider(thickness: 1, color: Colors.grey[300]),

                // Corpus Section
                const Text(
                  'Corpus:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),

                // Wrapping corpus in a Card with ListView
                Card(
                  child: Container(
                    constraints: const BoxConstraints(
                        maxHeight: 150), // Prevent overflow
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: corpus.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            corpus[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      },
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

  // Syllable Count Card
  Widget _buildSyllableCountCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Information Row
  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 8),
        Text(
          '$title: $value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
