import 'package:flutter/material.dart';

class PlayerResult {
  final String id;
  final String name;
  final int kills;
  final int deaths;

  const PlayerResult({
    required this.id,
    required this.name,
    required this.kills,
    required this.deaths,
  });
}

class ResultScreen extends StatelessWidget {
  final String winnerId;
  final String localPlayerId;
  final List<PlayerResult> resultList;

  const ResultScreen({
    super.key,
    required this.winnerId,
    required this.localPlayerId,
    required this.resultList,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocalWinner = winnerId == localPlayerId;
    final List<PlayerResult> sortedList = List.of(resultList)
      ..sort((PlayerResult a, PlayerResult b) => b.kills.compareTo(a.kills));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLocalWinner ? 'VICTORY!' : 'GAME OVER',
                style: TextStyle(
                  color: isLocalWinner
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFF44336),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Scoreboard
              Container(
                width: 400,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        SizedBox(width: 40, child: Text('#', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Player', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold))),
                        SizedBox(width: 60, child: Text('Kills', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold))),
                        SizedBox(width: 60, child: Text('Deaths', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(color: Color(0xFF444444)),
                    ...List.generate(sortedList.length, (int index) {
                      final PlayerResult result = sortedList[index];
                      final bool isFirst = index == 0;
                      final bool isLocal = result.id == localPlayerId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isFirst ? const Color(0xFFFFD700) : const Color(0xFFFFFFFF),
                                  fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${result.name}${isLocal ? " (You)" : ""}',
                                style: TextStyle(
                                  color: isLocal ? const Color(0xFF4CAF50) : const Color(0xFFFFFFFF),
                                  fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${result.kills}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${result.deaths}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
