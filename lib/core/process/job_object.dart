import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

const int _jobObjectLimitKillOnJobClose = 0x00002000;
const int _jobObjectExtendedLimitInformationClass = 9;

final class _JobObjectBasicLimitInformation extends Struct {
  @Int64()
  external int perProcessUserTimeLimit;
  @Int64()
  external int perJobUserTimeLimit;
  @Uint32()
  external int limitFlags;
  @Size()
  external int minimumWorkingSetSize;
  @Size()
  external int maximumWorkingSetSize;
  @Uint32()
  external int activeProcessLimit;
  @IntPtr()
  external int affinity;
  @Uint32()
  external int priorityClass;
  @Uint32()
  external int schedulingClass;
}

final class _IoCounters extends Struct {
  @Uint64()
  external int readOperationCount;
  @Uint64()
  external int writeOperationCount;
  @Uint64()
  external int otherOperationCount;
  @Uint64()
  external int readTransferCount;
  @Uint64()
  external int writeTransferCount;
  @Uint64()
  external int otherTransferCount;
}

final class _JobObjectExtendedLimitInformation extends Struct {
  external _JobObjectBasicLimitInformation basicLimitInformation;
  external _IoCounters ioInfo;
  @Size()
  external int processMemoryLimit;
  @Size()
  external int jobMemoryLimit;
  @Size()
  external int peakProcessMemoryLimit;
  @Size()
  external int peakJobMemoryLimit;
}

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

      final info = calloc<_JobObjectExtendedLimitInformation>();
      info.ref.basicLimitInformation.limitFlags = _jobObjectLimitKillOnJobClose;

      final res = SetInformationJobObject(
        _jobHandle,
        _jobObjectExtendedLimitInformationClass,
        info.cast(),
        sizeOf<_JobObjectExtendedLimitInformation>(),
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
