import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';

final currentStudentProvider = StateProvider<Student?>((ref) => null);
