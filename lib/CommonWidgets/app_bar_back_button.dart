import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Visibility(
          visible: MediaQuery.of(context).size.width < 600,
          child: IconButton(
            tooltip: _toolTipText(state),
            onPressed: cubit.backPressed,
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
        );
      },
    );
  }
}
/// Text for the tooltip of the back button
/// based on pageStatus
String _toolTipText(AppState state){
  if (state.pageStatus== AppPageStatus.resource){
    return 'Back to Skill Tree';
  }else
  if (state.pageStatus==AppPageStatus.skillTree){
    return 'Back to Profile';
  }else{
    return 'Back';
  }

}
