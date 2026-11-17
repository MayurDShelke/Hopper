import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

class WindowsJobObject {
  int _jobHandle = 0;
  bool _initialized = false;

  void initialize() {
    if (!Platform.isWindows || _initialized) return;

    try {
      _jobHandle = CreateJobObject(nullptr, nullptr);
      if (_jobHandle == 0) {
        debugPrint('Failed to create Win32 Job Object.');
        return;
      }

      final info = calloc<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>();
      info.ref.BasicLimitInformation.LimitFlags =
          JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;

      final res = SetInformationJobObject(
        _jobHandle,
        JOBOBJECTINFOCLASS.JobObjectExtendedLimitInformation,
        info.cast(),
        sizeOf<JOBOBJECT_EXTENDED_LIMIT_INFORMATION>(),
      );

      calloc.free(info);

      if (res != 0) {
        _initialized = true;
        debugPrint('Win32 Job Object initialized with KILL_ON_JOB_CLOSE.');
      } else {
        CloseHandle(_jobHandle);
        _jobHandle = 0;
      }
    } catch (e) {
      debugPrint('Win32 Job Object notice: $e');
    }
  }

  void assignProcess(int processPid) {
    if (!Platform.isWindows || !_initialized || _jobHandle == 0) return;

    try {
      final hProcess = OpenProcess(
        PROCESS_SET_QUOTA | PROCESS_TERMINATE,
        FALSE,
        processPid,
      );

      if (hProcess != 0) {
        AssignProcessToJobObject(_jobHandle, hProcess);
        CloseHandle(hProcess);
      }
    } catch (e) {
      debugPrint('Failed to assign PID $processPid to Job Object: $e');
    }
  }

  void dispose() {
    if (_jobHandle != 0) {
      CloseHandle(_jobHandle);
      _jobHandle = 0;
      _initialized = false;
    }
  }
}
