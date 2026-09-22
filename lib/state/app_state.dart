import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../models/post.dart';
import '../models/project.dart';

final _db = FirebaseFirestore.instance;

/// Current signed-in user, resolved from Firebase Auth + their matching
/// `employees/{uid}` Firestore doc. Null means "show the login screen."
class SessionNotifier extends StateNotifier<Employee?> {
  SessionNotifier() : super(null) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _employeeSub?.cancel();
      if (user == null) {
        state = null;
        return;
      }
      _employeeSub = _db.collection('employees').doc(user.uid).snapshots().listen((doc) {
        state = doc.exists ? Employee.fromMap(doc.id, doc.data()!) : null;
      });
    });
  }

  late final StreamSubscription<User?> _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _employeeSub;

  /// Returns an error message on failure, null on success.
  Future<String?> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
        case 'user-not-found':
        case 'wrong-password':
          return 'Incorrect email or password.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled. Contact your workspace admin.';
        case 'too-many-requests':
          return 'Too many attempts — try again in a moment.';
        default:
          return e.message ?? 'Could not sign in.';
      }
    }
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  void dispose() {
    _authSub.cancel();
    _employeeSub?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, Employee?>((ref) => SessionNotifier());

class EmployeesNotifier extends StateNotifier<List<Employee>> {
  EmployeesNotifier() : super([]) {
    _sub = _db.collection('employees').snapshots().listen((snap) {
      state = snap.docs.map((d) => Employee.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  /// Creates a real Firebase Auth account + matching Firestore doc. Uses a
  /// secondary (throwaway) FirebaseApp instance so creating the account
  /// doesn't sign the admin out of their own session — a well-known
  /// Firebase Auth client-SDK quirk (createUser signs in as that user on
  /// whichever app instance made the call).
  Future<Employee> addEmployee({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('employee-provisioning');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(name: 'employee-provisioning', options: Firebase.app().options);
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final uid = credential.user!.uid;
    await secondaryAuth.signOut();

    final employee = Employee(id: uid, name: name, email: email.trim(), role: role);
    await _db.collection('employees').doc(uid).set(employee.toMap());
    return employee;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final employeesProvider = StateNotifierProvider<EmployeesNotifier, List<Employee>>((ref) => EmployeesNotifier());

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _sub = _db.collection('projects').snapshots().listen((snap) {
      state = snap.docs.map((d) => Project.fromMap(d.id, d.data())).toList();
    });
  }

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  int get _nextNumber => state.fold<int>(0, (m, p) => p.number > m ? p.number : m) + 1;

  Future<Project> create({
    required String title,
    required String employeeId,
    required String sourceBrief,
  }) async {
    final project = Project(
      id: '',
      number: _nextNumber,
      title: title,
      employeeId: employeeId,
      sourceBrief: sourceBrief,
      createdAt: DateTime.now(),
    );
    final ref = await _db.collection('projects').add(project.toMap());
    return Project(
      id: ref.id,
      number: project.number,
      title: project.title,
      employeeId: project.employeeId,
      sourceBrief: project.sourceBrief,
      createdAt: project.createdAt,
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) => ProjectsNotifier());

class PostsNotifier extends StateNotifier<List<Post>> {
  PostsNotifier() : super([]) {
    _sub = _db.collection('posts').snapshots().listen((snap) {
      state = snap.docs.map((d) => Post.fromMap(d.id, d.data())).toList();
    });
  }

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _sub;

  int get _nextNumber => state.fold<int>(0, (m, p) => p.number > m ? p.number : m) + 1;

  Future<void> _update(String id, Map<String, dynamic> Function() fields) {
    return _db.collection('posts').doc(id).update(fields());
  }

  Future<void> saveDraft(String id, {required String caption, required String imageUrl, required String notes}) {
    return _update(id, () => {'caption': caption, 'imageUrl': imageUrl, 'notes': notes});
  }

  Future<void> submit(String id, {required String caption, required String imageUrl, required String notes}) {
    return _update(
      id,
      () => {
        'caption': caption,
        'imageUrl': imageUrl,
        'notes': notes,
        'status': PostStatus.submitted.id,
        'submittedAt': Timestamp.now(),
        'feedback': '',
      },
    );
  }

  Future<void> approve(String id) => _update(id, () => {'status': PostStatus.approved.id});

  Future<void> reject(String id, String feedback) =>
      _update(id, () => {'status': PostStatus.needsRevision.id, 'feedback': feedback});

  Future<void> editCaption(String id, String caption) => _update(id, () => {'caption': caption});

  Future<void> toggleScheduled(String id) {
    final current = state.firstWhere((p) => p.id == id).scheduled;
    return _update(id, () => {'scheduled': !current});
  }

  Future<Post> createPost({
    required String projectId,
    required String title,
    required DateTime dueDate,
    String referenceLink = '',
    List<String> factCheckNotes = const [],
    String styleNotes = '',
    String caption = '',
    String imageUrl = '',
    String notes = '',
    bool submit = false,
  }) async {
    final post = Post(
      id: '',
      number: _nextNumber,
      projectId: projectId,
      title: title,
      dueDate: dueDate,
      status: submit ? PostStatus.submitted : PostStatus.pending,
      referenceLink: referenceLink,
      factCheckNotes: factCheckNotes,
      styleNotes: styleNotes,
      caption: caption,
      imageUrl: imageUrl,
      notes: notes,
      submittedAt: submit ? DateTime.now() : null,
    );
    final ref = await _db.collection('posts').add(post.toMap());
    return Post.fromMap(ref.id, post.toMap());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, List<Post>>((ref) => PostsNotifier());

/// Posts belonging to a given project id.
final postsByProjectProvider = Provider.family<List<Post>, String>((ref, projectId) {
  return ref.watch(postsProvider).where((p) => p.projectId == projectId).toList()
    ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
});

/// The one project belonging to an employee (1:1 employee↔project per the
/// data model — an employee may still have zero if none assigned yet).
final projectForEmployeeProvider = Provider.family<Project?, String>((ref, employeeId) {
  final projects = ref.watch(projectsProvider);
  for (final p in projects) {
    if (p.employeeId == employeeId) return p;
  }
  return null;
});

final employeeByIdProvider = Provider.family<Employee?, String>((ref, id) {
  for (final e in ref.watch(employeesProvider)) {
    if (e.id == id) return e;
  }
  return null;
});
