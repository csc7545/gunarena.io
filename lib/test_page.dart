import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gun_arena_io/test_cubit.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TestCubit(),
      child: Scaffold(
        body: BlocBuilder<TestCubit, TestCubitState>(
          builder: (context, state) {
            return Center(
              child: GestureDetector(
                onTap: () => context.read<TestCubit>().increament(),
                child: Text(state.count.toString()),
              ),
            );
          },
        ),
      ),
    );
  }
}
