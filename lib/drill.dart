// DATA MODEL: training drill.
class Drill {
  final String title;
  final String level;
  final int minutes;
  final String instructions;

  const Drill(
    this.title,
    this.level,
    this.minutes,
    this.instructions,
  );
}

const drills = [
  Drill(
    'Backhand Throw',
    'Beginner',
    15,
    '1. Warm up your wrists and shoulders.\n'
        '2. Hold the disc with your thumb on top.\n'
        '3. Stand sideways toward your partner.\n'
        '4. Step and release the disc flat.\n'
        '5. Practice 20 short throws, focusing on accuracy.',
  ),
  Drill(
    'Forehand Throw',
    'Beginner',
    15,
    '1. Place two fingers under the rim and your thumb on top.\n'
        '2. Keep your elbow close to your body.\n'
        '3. Flick your wrist while keeping the disc flat.\n'
        '4. Practice 20 short throws with a partner.',
  ),
  Drill(
    'Pancake Catch',
    'Beginner',
    10,
    '1. Stand facing your partner.\n'
        '2. Watch the disc as it approaches.\n'
        '3. Catch it between your hands, one above and one below.\n'
        '4. Complete 20 catches from a short distance.',
  ),
  Drill(
    'Pivot and Pass',
    'Intermediate',
    20,
    '1. Mark one foot as your pivot foot.\n'
        '2. Keep it in place while stepping with your other foot.\n'
        '3. Practice passes around a cone.\n'
        '4. Complete 10 passes on each side.',
  ),
  Drill(
    'Cutting and Footwork',
    'Intermediate',
    20,
    '1. Set up three cones in a zigzag.\n'
        '2. Jog toward a cone and change direction.\n'
        '3. Accelerate into open space for a pass.\n'
        '4. Repeat five times, resting between rounds.',
  ),
  Drill(
    'Long Throw Accuracy',
    'Advanced',
    25,
    '1. Warm up with short passes.\n'
        '2. Place a target cone 20 meters away.\n'
        '3. Throw toward the target using controlled power.\n'
        '4. Record accurate throws out of 10 attempts.\n'
        '5. Increase distance gradually.',
  ),
];
