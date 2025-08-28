import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

void main() {
  group('Horse height conversions', () {
    test('cmToHands returns whole hands only', () {
      // 254 cm = 100 inches = 25 hands
      expect(cmToHands(254), 25);

      // Non-exact cm value should floor the result
      // 149 cm ≈ 58.66 inches -> 14 hands (remainder ≈ 2.66")
      expect(cmToHands(149), 14);
    });

    test('cmToHandsRemainder returns inches 0–3', () {
      // Exact multiple of 4 inches -> remainder 0
      expect(cmToHandsRemainder(254), 0);

      // 149 cm ≈ 58.66 inches -> remainder ≈ 2.66" -> 2
      expect(cmToHandsRemainder(149), inInclusiveRange(0, 3));
      expect(cmToHandsRemainder(149), 2);

      // 150 cm ≈ 59.06 inches -> remainder ≈ 3.06" -> 3
      expect(cmToHandsRemainder(150), 3);
    });

    test('cmToHandsAndInches encodes inches as decimal digit', () {
      // 254 cm = 25.0 (25 hands, 0 inches)
      expect(cmToHandsAndInches(254), closeTo(25.0, 1e-9));

      // 149 cm ≈ 14 hands 2 inches -> 14.2
      expect(cmToHandsAndInches(149), closeTo(14.2, 0.2));

      // 150 cm ≈ 14 hands 3 inches -> 14.3
      // Tolerate small floating-point error
      expect(cmToHandsAndInches(150), closeTo(14.3, 0.2));
    });

    test('handsAndInchesToCm converts to truncated cm', () {
      // 14 hands 3 inches = 59 inches = 149.86 cm -> toInt() => 149
      expect(handsAndInchesToCm(14, 3), 149);

      // 25 hands 0 inches = 254 cm
      expect(handsAndInchesToCm(25, 0), 254);
    });

    test('handsToCm rounds to nearest whole cm', () {
      // 1 hand = 10.16 cm -> round => 10
      expect(handsToCm(1), 10);

      // 25 hands = 254.0 cm -> 254
      expect(handsToCm(25), 254);
    });
  });
}
