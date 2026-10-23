import 'api_client.dart';
import 'registration_data.dart';

/// Live mode: saves the registration to the server. Files are uploaded only
/// when the member picked a new one, then the details are saved with their ids.
Future<void> pushRegistration({
  bool withVideo = false,
  void Function(String statusKey)? onStatus,
}) async {
  final r = registration;
  if (r.idPath != null && r.idPath != r.idUploadedFrom) {
    onStatus?.call('reg_up_id');
    final f = await api.uploadFile('idProof', r.idPath!, name: r.idFile);
    r.idProofFileId = f.id;
    r.idUploadedFrom = r.idPath;
  }
  if (r.photoPath != null && r.photoPath != r.photoUploadedFrom) {
    onStatus?.call('reg_up_photo');
    final f = await api.uploadFile('photo', r.photoPath!, name: r.photoFile);
    r.photoFileId = f.id;
    r.photoUploadedFrom = r.photoPath;
  }
  if (withVideo && r.videoPath != null && r.videoPath != r.videoUploadedFrom) {
    onStatus?.call('reg_up_video');
    final f = await api.uploadFile('video', r.videoPath!);
    r.videoFileId = f.id;
    r.videoUploadedFrom = r.videoPath;
  }
  onStatus?.call('reg_up_save');
  await api.saveRegistration(r.toApi());
}

/// Uploads everything, saves, and submits the registration for approval.
Future<void> submitRegistrationToServer({void Function(String statusKey)? onStatus}) async {
  await pushRegistration(withVideo: true, onStatus: onStatus);
  onStatus?.call('reg_up_submit');
  await api.submitRegistration();
}

/// A readable message for a rejected save (names the fields the server refused).
String describeApiError(ApiException e) {
  if (e.fields.isEmpty) return e.message;
  return '${e.message} (${e.fields.keys.join(', ')})';
}
