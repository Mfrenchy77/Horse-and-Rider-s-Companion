// lib/Resources/articles/create_article_page.dart
import 'package:database_repository/database_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Article/create_article_view.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Article/cubit/create_article_cubit.dart';

class CreateArticlePage extends StatelessWidget {
  const CreateArticlePage({super.key, this.onCreated});
  final void Function(String resourceId)? onCreated;

  static const name = 'CreateArticlePage';
  static const path = '/Resources/CreateArticle';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateArticleCubit>(
      create: (_) => CreateArticleCubit(
        resourcesRepository: ResourcesRepository(),
        storage: FirebaseStorage.instance,
        user: context.read<AppCubit>().state.usersProfile,
      ),
      child: CreateArticleView(onCreated: onCreated),
    );
  }
}
