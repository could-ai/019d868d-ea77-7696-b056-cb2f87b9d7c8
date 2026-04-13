import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const OmarsFootballApp());
}

class OmarsFootballApp extends StatelessWidget {
  const OmarsFootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omars Football',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  
  // Game state
  double playerX = 150;
  double playerY = 300;
  double playerSpeed = 200; // pixels per second
  
  double ballX = 200;
  double ballY = 200;
  double ballVX = 0;
  double ballVY = 0;
  double ballFriction = 0.98;
  
  int score = 0;
  
  // Input state
  double joystickX = 0;
  double joystickY = 0;
  bool isKicking = false;
  
  // Pitch dimensions (will be updated on layout)
  double pitchWidth = 400;
  double pitchHeight = 600;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    // Delta time in seconds (approximate 60fps = 0.016s)
    // For simplicity, we'll use a fixed dt or calculate it
    // Actually, let's just use a fixed small dt for stability
    double dt = 0.016;
    
    setState(() {
      // Move player
      playerX += joystickX * playerSpeed * dt;
      playerY += joystickY * playerSpeed * dt;
      
      // Clamp player to pitch
      playerX = playerX.clamp(20, pitchWidth - 20);
      playerY = playerY.clamp(20, pitchHeight - 20);
      
      // Move ball
      ballX += ballVX * dt;
      ballY += ballVY * dt;
      
      // Apply friction
      ballVX *= ballFriction;
      ballVY *= ballFriction;
      
      // Stop ball if very slow
      if (ballVX.abs() < 5) ballVX = 0;
      if (ballVY.abs() < 5) ballVY = 0;
      
      // Ball collision with walls
      if (ballX <= 10) {
        ballX = 10;
        ballVX = -ballVX * 0.8;
      } else if (ballX >= pitchWidth - 10) {
        ballX = pitchWidth - 10;
        ballVX = -ballVX * 0.8;
      }
      
      if (ballY <= 10) {
        // Top wall - check for goal
        if (ballX > pitchWidth / 2 - 50 && ballX < pitchWidth / 2 + 50) {
          // GOAL!
          score++;
          _resetPositions();
        } else {
          ballY = 10;
          ballVY = -ballVY * 0.8;
        }
      } else if (ballY >= pitchHeight - 10) {
        ballY = pitchHeight - 10;
        ballVY = -ballVY * 0.8;
      }
      
      // Player and ball collision / kicking
      double dx = ballX - playerX;
      double dy = ballY - playerY;
      double distance = sqrt(dx * dx + dy * dy);
      
      if (distance < 30) {
        // Push ball away
        double pushForce = isKicking ? 500 : 100;
        double angle = atan2(dy, dx);
        ballVX = cos(angle) * pushForce;
        ballVY = sin(angle) * pushForce;
        
        if (isKicking) {
          isKicking = false; // Reset kick after contact
        }
      }
    });
  }

  void _resetPositions() {
    playerX = pitchWidth / 2;
    playerY = pitchHeight - 100;
    ballX = pitchWidth / 2;
    ballY = pitchHeight / 2;
    ballVX = 0;
    ballVY = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Scoreboard
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OMARS FOOTBALL',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'SCORE: $score',
                    style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Game Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  pitchWidth = constraints.maxWidth;
                  pitchHeight = constraints.maxHeight;
                  
                  return GestureDetector(
                    onPanStart: (details) => _updateJoystick(details.localPosition, constraints),
                    onPanUpdate: (details) => _updateJoystick(details.localPosition, constraints),
                    onPanEnd: (_) => _resetJoystick(),
                    child: CustomPaint(
                      size: Size(pitchWidth, pitchHeight),
                      painter: PitchPainter(
                        playerX: playerX,
                        playerY: playerY,
                        ballX: ballX,
                        ballY: ballY,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Controls Area
            Container(
              height: 120,
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Virtual Joystick visualization
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        transform: Matrix4.translationValues(joystickX * 30, joystickY * 30, 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  
                  // Kick Button
                  GestureDetector(
                    onTapDown: (_) => setState(() => isKicking = true),
                    onTapUp: (_) => setState(() => isKicking = false),
                    onTapCancel: () => setState(() => isKicking = false),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isKicking ? Colors.red[700] : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'KICK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateJoystick(Offset position, BoxConstraints constraints) {
    // We'll use the bottom left area for joystick if touched there, 
    // but since we have a dedicated control area, let's just use the touch on the pitch for movement for now,
    // or better, let's make the joystick area handle the pan.
    // Actually, let's just use a simple tap-to-move or drag-to-move on the pitch.
    
    // Calculate direction from player to touch
    double dx = position.dx - playerX;
    double dy = position.dy - playerY;
    double distance = sqrt(dx * dx + dy * dy);
    
    if (distance > 0) {
      setState(() {
        joystickX = dx / distance;
        joystickY = dy / distance;
      });
    }
  }

  void _resetJoystick() {
    setState(() {
      joystickX = 0;
      joystickY = 0;
    });
  }
}

class PitchPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double ballX;
  final double ballY;

  PitchPainter({
    required this.playerX,
    required this.playerY,
    required this.ballX,
    required this.ballY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grass
    final grassPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);
    
    // Draw pitch lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    // Outer bounds
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), linePaint);
    
    // Center line
    canvas.drawLine(Offset(10, size.height / 2), Offset(size.width - 10, size.height / 2), linePaint);
    
    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, linePaint);
    
    // Top penalty area
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 100, 10, 200, 80), linePaint);
    
    // Bottom penalty area
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 100, size.height - 90, 200, 80), linePaint);
    
    // Top Goal
    final goalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawLine(Offset(size.width / 2 - 50, 10), Offset(size.width / 2 + 50, 10), goalPaint);
    
    // Draw Player
    final playerPaint = Paint()..color = Colors.blue;
    canvas.drawCircle(Offset(playerX, playerY), 15, playerPaint);
    
    // Draw Player direction indicator (nose)
    final nosePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(playerX, playerY - 10), 5, nosePaint);

    // Draw Ball
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(ballX, ballY), 10, ballPaint);
    
    // Ball pattern (simple pentagon/hexagon illusion)
    final ballDetailPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(ballX, ballY), 4, ballDetailPaint);
  }

  @override
  bool shouldRepaint(covariant PitchPainter oldDelegate) {
    return oldDelegate.playerX != playerX ||
           oldDelegate.playerY != playerY ||
           oldDelegate.ballX != ballX ||
           oldDelegate.ballY != ballY;
  }
}
