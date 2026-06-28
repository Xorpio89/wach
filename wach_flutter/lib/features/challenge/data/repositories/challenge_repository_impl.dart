import 'dart:async';

import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_local_datasource.dart';
import '../models/challenge_model.dart';

/// Challenge Repository Implementation - Data Layer
class ChallengeRepositoryImpl implements ChallengeRepository {
  final ChallengeLocalDataSource _localDataSource;

  final _controller = StreamController<List<Challenge>>.broadcast();

  ChallengeRepositoryImpl(this._localDataSource);

  @override
  Future<List<Challenge>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Challenge?> getById(String id) async {
    final model = await _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Challenge> create(Challenge challenge) async {
    await _localDataSource.insert(ChallengeModel.fromEntity(challenge));
    _notifyListeners();
    return challenge;
  }

  @override
  Future<Challenge> update(Challenge challenge) async {
    await _localDataSource.update(ChallengeModel.fromEntity(challenge));
    _notifyListeners();
    return challenge;
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
    _notifyListeners();
  }

  @override
  Stream<List<Challenge>> watchAll() {
    getAll().then((challenges) {
      if (!_controller.isClosed) _controller.add(challenges);
    });
    return _controller.stream;
  }

  Future<void> _notifyListeners() async {
    final challenges = await getAll();
    if (!_controller.isClosed) _controller.add(challenges);
  }

  void dispose() {
    _controller.close();
  }
}
