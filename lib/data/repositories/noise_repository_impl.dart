// 仓储实现：桥接领域与数据源
import '../../domain/entities/noise_sample.dart';
import '../../domain/repositories/noise_repository.dart';
import '../datasources/audio/noise_datasource.dart';

class NoiseRepositoryImpl implements NoiseRepository {
  final NoiseDataSource dataSource;
  NoiseRepositoryImpl(this.dataSource);

  @override
  Future<void> start() => dataSource.start();

  @override
  Future<void> stop() => dataSource.stop();

  @override
  Stream<NoiseSample> stream() => dataSource.stream();
}
