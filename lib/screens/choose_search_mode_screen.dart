import 'package:flutter/material.dart';
import 'search_method_screen.dart';

class ChooseSearchModeScreen extends StatefulWidget {
  const ChooseSearchModeScreen({super.key});

  @override
  State<ChooseSearchModeScreen> createState() => _ChooseSearchModeScreenState();
}

class _ChooseSearchModeScreenState extends State<ChooseSearchModeScreen> {
  @override
  Widget build(BuildContext context) {
    return const SearchMethodScreen();
  }
}