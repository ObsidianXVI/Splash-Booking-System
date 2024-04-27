part of splash;

class GoogleCloudLoggingService {
  late LoggingApi _loggingApi; // Instance variable for Cloud Logging API
  bool _isSetup = false; // Indicator to check if the API setup is complete

  // Method to set up the Cloud Logging API
  Future<void> setupLoggingApi() async {
    if (_isSetup) return;

    try {
      final credentials =
          ServiceAccountCredentials.fromJson(serviceAccountCredentials);

      final authClient = await clientViaServiceAccount(
        credentials,
        [LoggingApi.loggingWriteScope],
      );

      _loggingApi = LoggingApi(authClient);
      _isSetup = true;
      debugPrint('Cloud Logging API setup for $projectId');
    } catch (error) {
      debugPrint('Error setting up Cloud Logging API: $error');
    }
  }

  void writeLog({required Level level, required String message}) {
    if (!_isSetup) {
      debugPrint('Cloud Logging API is not setup, aborting operation');
      return;
    }

    // Create a log entry
    final logEntry = LogEntry()
      ..logName = 'projects/$projectId/logs/app-$userId'
      ..jsonPayload = {'message': message}
      ..resource = (MonitoredResource()..type = 'global')
      ..severity = 'ERROR'
      ..labels = {
        'project_id': projectId,
        'level': level.name.toUpperCase(),
        'user_id': userId,
      };

    // Create a write log entries request
    final request = WriteLogEntriesRequest()..entries = [logEntry];

    // Write the log entry using the Logging API and handle errors
    _loggingApi.entries.write(request).catchError((error) {
      debugPrint('Error writing log entry $error');
      return WriteLogEntriesResponse();
    });
  }
}