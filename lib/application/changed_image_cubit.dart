import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gun_arena_io/application/changed_image_state.dart';
import 'package:gun_arena_io/repository/changed_image_repository.dart';

class ChangedImageCubit extends Cubit<ChangedImageState> {
  ChangedImageCubit() : super(ImageInitState());

  final ChangedImageRepository _repository = ChangedImageRepository.instance;

  Future<void> getImage() async {
    emit(ImageLoadingState(pageNo: state.pageNo));
  }
}
