import 'package:get/get.dart';
import '../../../core/mixins/animation_mixin.dart';
import '../../../core/mixins/dimension_mixin.dart';

class CustomDecoratedTextController extends GetxController with AnimationMixin, DimensionMixin {
  // Properties are now inherited from mixins
  // maxWidth from DimensionMixin
  // isExpanded and animationDuration from AnimationMixin
}
