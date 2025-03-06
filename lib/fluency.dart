import 'package:flutter/material.dart';

class AIOutputVisualization extends StatelessWidget {
  final List<int> syllableCount;
  final bool isCorrect;
  final double score;
  final List<String> corpus;
  final int repCount;
  final int proCount;
  final int blockCount;

  const AIOutputVisualization({
    super.key,
    required this.syllableCount,
    required this.isCorrect,
    required this.score,
    required this.corpus,
    required this.repCount,
    required this.proCount,
    required this.blockCount,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AI Output"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Syllable Count"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("Input Syllables", syllableCount[0],
                      Icons.text_fields, Colors.blue),
                  _buildStatCard("Output Syllables", syllableCount[1],
                      Icons.volume_up, Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              _buildInfoRow("Is Correct", isCorrect ? "Yes" : "No",
                  Icons.check_circle, isCorrect ? Colors.green : Colors.red),
              _buildInfoRow(
                  "Score", score.toStringAsFixed(2), Icons.star, Colors.amber),
              const SizedBox(height: 16),
              _buildDivider(),
              _buildSectionTitle("Speech Analysis"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                      "Repetition", repCount, Icons.replay, Colors.orange),
                  _buildStatCard("Prolongation", proCount,
                      Icons.slow_motion_video, Colors.purple),
                  _buildStatCard("Block", blockCount, Icons.block, Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              _buildSectionTitle("Corpus"),
              _buildCorpusList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(count.toString(),
                  style: TextStyle(
                      fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Text(
            "$title: $value",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpusList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount:
              1, // Always render one item since corpus has either 1 or 2 elements
          itemBuilder: (context, index) {
            if (corpus.length == 1) {
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text('Output - ${corpus[0]}',
                    style: const TextStyle(fontSize: 16)),
              );
            } else if (corpus.length == 2) {
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text('Input Phoneme:    ${corpus[0]}',
                        style: const TextStyle(fontSize: 16)),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text('Output Phoneme:    ${corpus[1]}',
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              );
            }
            return const SizedBox
                .shrink(); // Handle unexpected cases gracefully
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(thickness: 1, color: Colors.grey[300]);
  }
}
