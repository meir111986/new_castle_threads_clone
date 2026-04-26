import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threads_clone/data/models/comment_model.dart';
import 'package:threads_clone/data/models/post_model.dart';
import 'package:threads_clone/domain/entities/post.dart';
import 'package:threads_clone/domain/repositories/auth_repository.dart';
import 'package:threads_clone/domain/repositories/post_repository.dart';
import 'package:threads_clone/firebase_options.dart';
import 'package:threads_clone/locator.dart';
import 'package:threads_clone/presentation/bloc/auth/auth_cubit.dart';
import 'package:threads_clone/presentation/bloc/feed_cubit.dart';
import 'package:threads_clone/presentation/widgets/auth_wrapper.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBgHandler);

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['API_URL'] ?? '',
    anonKey: dotenv.env['API_KEY'] ?? '',
  );

  await Hive.initFlutter();
  Hive.registerAdapter(PostModelAdapter());
  Hive.registerAdapter(CommentModelAdapter());
  await _seedData();

  await setupDependencies();

  runApp(const MyApp());
}

Future<void> _seedData() async {
  final box = await Hive.openBox<PostModel>('posts');

  final posts = [
    Post(
      id: '1',
      content: 'Красивый день в Астана!',
      authorId: '1',
      createdAt: DateTime.now().toString(),
      likes: 3,
    ),
    Post(
      id: '2',
      content: 'Workng on my Flutter project!',
      authorId: '2',
      createdAt: DateTime.now().toString(),
      likes: 6,
    ),
    Post(
      id: '3',
      content: 'Знакомьтесь, это мой новый пост!',
      authorId: '3',
      createdAt: DateTime.now().toString(),
      likes: 9,
    ),
  ];

  await box.putAll(
    posts.asMap().map(
      (key, post) => MapEntry(post.id, PostModel.fromEntity(post)),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(locator<AuthRepository>())..checkAuth(),
        ),
        BlocProvider(create: (_) => FeedCubit(locator<PostRepository>())),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: const AuthWrapper(),
      ),
    );
  }
}
