using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public sealed class Room407ExportJobRun : IDisposable
{
    private const uint JobLimitKillOnClose = 0x00002000;
    private const int JobExtendedLimitInformation = 9;
    private const int JobBasicAccountingInformation = 1;
    private const uint CreateSuspended = 0x00000004;
    private const uint CreateNoWindow = 0x08000000;
    private const uint ExtendedStartupInfoPresent = 0x00080000;
    private const uint StartfUseStdHandles = 0x00000100;
    private const int ProcThreadAttributeHandleList = 0x00020002;
    private const uint GenericRead = 0x80000000;
    private const uint GenericWrite = 0x40000000;
    private const uint FileShareRead = 0x00000001;
    private const uint FileShareWrite = 0x00000002;
    private const uint CreateAlways = 2;
    private const uint OpenExisting = 3;
    private const uint FileAttributeNormal = 0x00000080;
    private const uint WaitObject0 = 0;
    private const uint WaitTimeout = 258;
    private const uint HandleFlagInherit = 0x00000001;
    private const int ErrorBrokenPipe = 109;
    private const int ErrorNoData = 232;
    private const int ErrorOperationAborted = 995;
    private const uint ThreadTerminateAccess = 0x0001;
    private const int OutputPumpBufferSize = 8192;
    private const int DisposePumpGraceMilliseconds = 5000;
    private const int DisposePumpForceCloseMilliseconds = 25000;
    private const int DisposeJobWaitMilliseconds = 30000;
    private static readonly IntPtr InvalidHandle = new IntPtr(-1);

    [StructLayout(LayoutKind.Sequential)]
    private struct SecurityAttributes
    {
        public int Length;
        public IntPtr SecurityDescriptor;
        [MarshalAs(UnmanagedType.Bool)] public bool InheritHandle;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct StartupInfo
    {
        public int Size;
        public string Reserved;
        public string Desktop;
        public string Title;
        public int X;
        public int Y;
        public int XSize;
        public int YSize;
        public int XChars;
        public int YChars;
        public int FillAttribute;
        public int Flags;
        public short ShowWindow;
        public short ReservedSize;
        public IntPtr ReservedPointer;
        public IntPtr StandardInput;
        public IntPtr StandardOutput;
        public IntPtr StandardError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct StartupInfoEx
    {
        public StartupInfo Startup;
        public IntPtr AttributeList;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessInformation
    {
        public IntPtr Process;
        public IntPtr Thread;
        public uint ProcessId;
        public uint ThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct NativeFileTime
    {
        public uint LowDateTime;
        public uint HighDateTime;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicLimitInformation
    {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IoCounters
    {
        public ulong ReadOperationCount;
        public ulong WriteOperationCount;
        public ulong OtherOperationCount;
        public ulong ReadTransferCount;
        public ulong WriteTransferCount;
        public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ExtendedLimitInformation
    {
        public BasicLimitInformation BasicLimit;
        public IoCounters IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicAccountingInformation
    {
        public long TotalUserTime;
        public long TotalKernelTime;
        public long PeriodUserTime;
        public long PeriodKernelTime;
        public uint TotalPageFaultCount;
        public uint TotalProcesses;
        public uint ActiveProcesses;
        public uint TotalTerminatedProcesses;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr securityAttributes, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(
        IntPtr job,
        int informationClass,
        ref ExtendedLimitInformation information,
        uint informationLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool QueryInformationJobObject(
        IntPtr job,
        int informationClass,
        ref BasicAccountingInformation information,
        uint informationLength,
        IntPtr returnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool TerminateJobObject(IntPtr job, uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CreateProcessW(
        string applicationName,
        StringBuilder commandLine,
        IntPtr processAttributes,
        IntPtr threadAttributes,
        [MarshalAs(UnmanagedType.Bool)] bool inheritHandles,
        uint creationFlags,
        IntPtr environment,
        string currentDirectory,
        ref StartupInfoEx startupInfo,
        out ProcessInformation processInformation);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateFileW(
        string fileName,
        uint desiredAccess,
        uint shareMode,
        ref SecurityAttributes securityAttributes,
        uint creationDisposition,
        uint flags,
        IntPtr templateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool InitializeProcThreadAttributeList(
        IntPtr attributeList,
        int attributeCount,
        int flags,
        ref IntPtr size);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool UpdateProcThreadAttribute(
        IntPtr attributeList,
        uint flags,
        IntPtr attribute,
        IntPtr value,
        IntPtr size,
        IntPtr previousValue,
        IntPtr returnSize);

    [DllImport("kernel32.dll")]
    private static extern void DeleteProcThreadAttributeList(IntPtr attributeList);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint ResumeThread(IntPtr thread);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool TerminateProcess(IntPtr process, uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetExitCodeProcess(IntPtr process, out uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CreatePipe(
        out IntPtr readPipe,
        out IntPtr writePipe,
        ref SecurityAttributes pipeAttributes,
        uint size);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetHandleInformation(IntPtr handle, uint mask, uint flags);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ReadFile(
        IntPtr file,
        [Out] byte[] buffer,
        uint bytesToRead,
        out uint bytesRead,
        IntPtr overlapped);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WriteFile(
        IntPtr file,
        IntPtr buffer,
        uint bytesToWrite,
        out uint bytesWritten,
        IntPtr overlapped);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenThread(
        uint desiredAccess,
        [MarshalAs(UnmanagedType.Bool)] bool inheritHandle,
        uint threadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CancelSynchronousIo(IntPtr thread);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint GetProcessId(IntPtr process);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetProcessTimes(
        IntPtr process,
        out NativeFileTime creationTime,
        out NativeFileTime exitTime,
        out NativeFileTime kernelTime,
        out NativeFileTime userTime);

    private sealed class OutputPumpState
    {
        public IntPtr ReadHandle;
        public IntPtr DestinationHandle;
        public IntPtr ThreadHandle;

        public OutputPumpState(IntPtr readHandle, IntPtr destinationHandle)
        {
            ReadHandle = readHandle;
            DestinationHandle = destinationHandle;
        }
    }

    private IntPtr jobHandle;
    private IntPtr processHandle;
    private bool disposed;
    private readonly object stateLock = new object();
    private readonly object outputLock = new object();
    private readonly uint processId;
    private readonly DateTime startedAtUtc;
    private readonly bool hasOutputPumps;
    private readonly long combinedOutputLimit;
    private long combinedOutputBytes;
    private bool outputLimitExceeded;
    private Exception outputPumpFailure;
    private OutputPumpState standardOutputPumpState;
    private OutputPumpState standardErrorPumpState;
    private Thread standardOutputPumpThread;
    private Thread standardErrorPumpThread;
    private bool standardOutputPumpStarted;
    private bool standardErrorPumpStarted;

    private Room407ExportJobRun(IntPtr job, IntPtr process)
    {
        jobHandle = job;
        processHandle = process;
        processId = GetProcessId(process);
        DateTime capturedStartedAtUtc;
        startedAtUtc = TryGetProcessStartedAtUtc(process, out capturedStartedAtUtc)
            ? capturedStartedAtUtc
            : DateTime.MinValue;
        hasOutputPumps = false;
        combinedOutputLimit = 0;
    }

    private Room407ExportJobRun(
        IntPtr job,
        IntPtr process,
        uint capturedProcessId,
        DateTime capturedStartedAtUtc,
        long outputLimit,
        OutputPumpState outputPump,
        OutputPumpState errorPump)
    {
        jobHandle = job;
        processHandle = process;
        processId = capturedProcessId;
        startedAtUtc = capturedStartedAtUtc;
        hasOutputPumps = true;
        combinedOutputLimit = outputLimit;
        standardOutputPumpState = outputPump;
        standardErrorPumpState = errorPump;
    }

    public uint ProcessId
    {
        get { return processId; }
    }

    public DateTime StartedAtUtc
    {
        get { return startedAtUtc; }
    }

    public bool OutputLimitExceeded
    {
        get
        {
            lock (outputLock)
            {
                return outputLimitExceeded;
            }
        }
    }

    private static IntPtr CreateKillOnCloseJob()
    {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        if (job == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        var information = new ExtendedLimitInformation();
        information.BasicLimit.LimitFlags = JobLimitKillOnClose;
        if (!SetInformationJobObject(
                job,
                JobExtendedLimitInformation,
                ref information,
                (uint)Marshal.SizeOf(typeof(ExtendedLimitInformation))))
        {
            int error = Marshal.GetLastWin32Error();
            CloseHandle(job);
            throw new Win32Exception(error);
        }
        return job;
    }

    private static IntPtr CreateInheritedFile(string path, uint access, uint disposition)
    {
        var attributes = new SecurityAttributes();
        attributes.Length = Marshal.SizeOf(typeof(SecurityAttributes));
        attributes.InheritHandle = true;
        IntPtr handle = CreateFileW(
            path,
            access,
            FileShareRead | FileShareWrite,
            ref attributes,
            disposition,
            FileAttributeNormal,
            IntPtr.Zero);
        if (handle == InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error());
        return handle;
    }

    private static IntPtr CreateOutputFile(string path)
    {
        var attributes = new SecurityAttributes();
        attributes.Length = Marshal.SizeOf(typeof(SecurityAttributes));
        attributes.InheritHandle = false;
        IntPtr handle = CreateFileW(
            path,
            GenericWrite,
            FileShareRead,
            ref attributes,
            CreateAlways,
            FileAttributeNormal,
            IntPtr.Zero);
        if (handle == InvalidHandle) throw new Win32Exception(Marshal.GetLastWin32Error());
        return handle;
    }

    private static bool TryGetProcessStartedAtUtc(IntPtr process, out DateTime value)
    {
        NativeFileTime creationTime;
        NativeFileTime exitTime;
        NativeFileTime kernelTime;
        NativeFileTime userTime;
        if (!GetProcessTimes(
                process,
                out creationTime,
                out exitTime,
                out kernelTime,
                out userTime))
        {
            value = DateTime.MinValue;
            return false;
        }
        long fileTime = ((long)creationTime.HighDateTime << 32) | creationTime.LowDateTime;
        value = DateTime.FromFileTimeUtc(fileTime);
        return true;
    }

    private static uint GetRequiredProcessId(IntPtr process)
    {
        uint value = GetProcessId(process);
        if (value == 0) throw new Win32Exception(Marshal.GetLastWin32Error());
        return value;
    }

    private static DateTime GetRequiredProcessStartedAtUtc(IntPtr process)
    {
        DateTime value;
        if (!TryGetProcessStartedAtUtc(process, out value))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        return value;
    }

    private static void CreateChildOutputPipe(out IntPtr readPipe, out IntPtr writePipe)
    {
        readPipe = IntPtr.Zero;
        writePipe = IntPtr.Zero;
        var attributes = new SecurityAttributes();
        attributes.Length = Marshal.SizeOf(typeof(SecurityAttributes));
        attributes.InheritHandle = true;
        if (!CreatePipe(out readPipe, out writePipe, ref attributes, 0))
        {
            int error = Marshal.GetLastWin32Error();
            // CreatePipe does not define either output on failure.
            readPipe = IntPtr.Zero;
            writePipe = IntPtr.Zero;
            throw new Win32Exception(error);
        }
        if (!SetHandleInformation(readPipe, HandleFlagInherit, 0))
        {
            int error = Marshal.GetLastWin32Error();
            CloseHandle(writePipe);
            CloseHandle(readPipe);
            readPipe = IntPtr.Zero;
            writePipe = IntPtr.Zero;
            throw new Win32Exception(error);
        }
    }

    private void StartOutputPumps()
    {
        standardOutputPumpThread = new Thread(new ParameterizedThreadStart(PumpOutput));
        standardOutputPumpThread.IsBackground = true;
        standardOutputPumpThread.Name = "Room407 stdout pump";
        standardErrorPumpThread = new Thread(new ParameterizedThreadStart(PumpOutput));
        standardErrorPumpThread.IsBackground = true;
        standardErrorPumpThread.Name = "Room407 stderr pump";
        try
        {
            standardOutputPumpThread.Start(standardOutputPumpState);
            standardOutputPumpStarted = true;
            standardErrorPumpThread.Start(standardErrorPumpState);
            standardErrorPumpStarted = true;
        }
        catch
        {
            if (!standardOutputPumpStarted) CloseOutputPumpStateNoThrow(standardOutputPumpState);
            if (!standardErrorPumpStarted) CloseOutputPumpStateNoThrow(standardErrorPumpState);
            throw;
        }
    }

    private void CloseOutputPumpStateNoThrow(OutputPumpState state)
    {
        if (state == null) return;
        IntPtr readHandle;
        IntPtr destinationHandle;
        IntPtr threadHandle;
        lock (stateLock)
        {
            readHandle = state.ReadHandle;
            state.ReadHandle = IntPtr.Zero;
            destinationHandle = state.DestinationHandle;
            state.DestinationHandle = IntPtr.Zero;
            threadHandle = state.ThreadHandle;
            state.ThreadHandle = IntPtr.Zero;
        }
        if (readHandle != IntPtr.Zero) CloseHandle(readHandle);
        if (destinationHandle != IntPtr.Zero) CloseHandle(destinationHandle);
        if (threadHandle != IntPtr.Zero) CloseHandle(threadHandle);
    }

    private void RegisterOutputPumpThread(OutputPumpState state)
    {
        IntPtr threadHandle = OpenThread(ThreadTerminateAccess, false, GetCurrentThreadId());
        if (threadHandle == IntPtr.Zero)
            throw new Win32Exception(Marshal.GetLastWin32Error());
        lock (stateLock)
        {
            state.ThreadHandle = threadHandle;
        }
    }

    private static void WriteOutputBytes(OutputPumpState state, byte[] buffer, int count)
    {
        GCHandle pinnedBuffer = GCHandle.Alloc(buffer, GCHandleType.Pinned);
        try
        {
            int offset = 0;
            while (offset != count)
            {
                uint bytesWritten;
                IntPtr address = Marshal.UnsafeAddrOfPinnedArrayElement(buffer, offset);
                if (!WriteFile(
                        state.DestinationHandle,
                        address,
                        (uint)(count - offset),
                        out bytesWritten,
                        IntPtr.Zero))
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                if (bytesWritten == 0)
                    throw new IOException("The process output pump wrote zero bytes before reaching its destination boundary.");
                offset += checked((int)bytesWritten);
            }
        }
        finally
        {
            pinnedBuffer.Free();
        }
    }

    private bool IsExpectedDisposeCancellation(Exception exception)
    {
        var win32Exception = exception as Win32Exception;
        if (win32Exception == null || win32Exception.NativeErrorCode != ErrorOperationAborted)
            return false;
        lock (stateLock)
        {
            return disposed;
        }
    }

    private void CancelOutputPumpIo(OutputPumpState state)
    {
        if (state == null) return;
        lock (stateLock)
        {
            if (state.ThreadHandle != IntPtr.Zero)
                CancelSynchronousIo(state.ThreadHandle);
        }
    }

    private void PumpOutput(object value)
    {
        var state = (OutputPumpState)value;
        var buffer = new byte[OutputPumpBufferSize];
        try
        {
            RegisterOutputPumpThread(state);
            while (true)
            {
                uint bytesRead;
                if (!ReadFile(
                        state.ReadHandle,
                        buffer,
                        (uint)buffer.Length,
                        out bytesRead,
                        IntPtr.Zero))
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error == ErrorBrokenPipe || error == ErrorNoData) break;
                    throw new Win32Exception(error);
                }
                if (bytesRead == 0) break;

                bool stopPumping;
                bool exceededOnThisRead = false;
                int bytesToWrite = 0;
                lock (outputLock)
                {
                    if (outputLimitExceeded)
                    {
                        stopPumping = true;
                    }
                    else
                    {
                        long remaining = combinedOutputLimit - combinedOutputBytes;
                        bytesToWrite = (int)Math.Min((long)bytesRead, remaining);
                        exceededOnThisRead = (long)bytesRead > remaining;
                        if (exceededOnThisRead) outputLimitExceeded = true;
                        // Reserve the shared budget before the file write. If a
                        // destination fails after a partial native write, the
                        // other pump still cannot consume those bytes again.
                        combinedOutputBytes += bytesToWrite;
                        stopPumping = exceededOnThisRead;
                    }
                }
                if (exceededOnThisRead) TerminateJobFromOutputPump();
                if (bytesToWrite != 0) WriteOutputBytes(state, buffer, bytesToWrite);
                if (stopPumping) break;
            }
        }
        catch (Exception exception)
        {
            if (!IsExpectedDisposeCancellation(exception))
            {
                RecordOutputPumpFailure(exception);
                TerminateJobFromOutputPump();
            }
        }
        finally
        {
            CloseOutputPumpStateNoThrow(state);
        }
    }

    private void RecordOutputPumpFailure(Exception exception)
    {
        lock (stateLock)
        {
            if (outputPumpFailure == null) outputPumpFailure = exception;
        }
    }

    private void TerminateJobFromOutputPump()
    {
        int error = 0;
        lock (stateLock)
        {
            if (jobHandle != IntPtr.Zero && !TerminateJobObject(jobHandle, 1))
                error = Marshal.GetLastWin32Error();
        }
        if (error != 0) RecordOutputPumpFailure(new Win32Exception(error));
    }

    public static Room407ExportJobRun Launch(
        string applicationName,
        string commandLine,
        string currentDirectory,
        string standardOutputPath,
        string standardErrorPath)
    {
        IntPtr job = IntPtr.Zero;
        IntPtr standardOutput = InvalidHandle;
        IntPtr standardError = InvalidHandle;
        IntPtr standardInput = InvalidHandle;
        IntPtr attributeList = IntPtr.Zero;
        IntPtr handleList = IntPtr.Zero;
        bool attributesInitialized = false;
        bool processCreated = false;
        var processInfo = new ProcessInformation();
        try
        {
            job = CreateKillOnCloseJob();
            standardOutput = CreateInheritedFile(standardOutputPath, GenericWrite, CreateAlways);
            standardError = CreateInheritedFile(standardErrorPath, GenericWrite, CreateAlways);
            standardInput = CreateInheritedFile("NUL", GenericRead, OpenExisting);

            IntPtr attributeBytes = IntPtr.Zero;
            InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref attributeBytes);
            attributeList = Marshal.AllocHGlobal(attributeBytes);
            if (!InitializeProcThreadAttributeList(attributeList, 1, 0, ref attributeBytes))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            attributesInitialized = true;

            handleList = Marshal.AllocHGlobal(IntPtr.Size * 3);
            Marshal.WriteIntPtr(handleList, 0, standardInput);
            Marshal.WriteIntPtr(handleList, IntPtr.Size, standardOutput);
            Marshal.WriteIntPtr(handleList, IntPtr.Size * 2, standardError);
            if (!UpdateProcThreadAttribute(
                    attributeList,
                    0,
                    new IntPtr(ProcThreadAttributeHandleList),
                    handleList,
                    new IntPtr(IntPtr.Size * 3),
                    IntPtr.Zero,
                    IntPtr.Zero))
                throw new Win32Exception(Marshal.GetLastWin32Error());

            var startup = new StartupInfoEx();
            startup.Startup.Size = Marshal.SizeOf(typeof(StartupInfoEx));
            startup.Startup.Flags = (int)StartfUseStdHandles;
            startup.Startup.StandardInput = standardInput;
            startup.Startup.StandardOutput = standardOutput;
            startup.Startup.StandardError = standardError;
            startup.AttributeList = attributeList;

            if (!CreateProcessW(
                    applicationName,
                    new StringBuilder(commandLine),
                    IntPtr.Zero,
                    IntPtr.Zero,
                    true,
                    CreateSuspended | CreateNoWindow | ExtendedStartupInfoPresent,
                    IntPtr.Zero,
                    currentDirectory,
                    ref startup,
                    out processInfo))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            processCreated = true;
            if (!AssignProcessToJobObject(job, processInfo.Process))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            if (ResumeThread(processInfo.Thread) == UInt32.MaxValue)
                throw new Win32Exception(Marshal.GetLastWin32Error());

            CloseHandle(processInfo.Thread);
            processInfo.Thread = IntPtr.Zero;
            var result = new Room407ExportJobRun(job, processInfo.Process);
            job = IntPtr.Zero;
            processInfo.Process = IntPtr.Zero;
            return result;
        }
        catch
        {
            if (processCreated && processInfo.Process != IntPtr.Zero)
            {
                TerminateProcess(processInfo.Process, 1);
                WaitForSingleObject(processInfo.Process, 10000);
            }
            throw;
        }
        finally
        {
            if (processInfo.Thread != IntPtr.Zero) CloseHandle(processInfo.Thread);
            if (processInfo.Process != IntPtr.Zero) CloseHandle(processInfo.Process);
            if (attributesInitialized) DeleteProcThreadAttributeList(attributeList);
            if (handleList != IntPtr.Zero) Marshal.FreeHGlobal(handleList);
            if (attributeList != IntPtr.Zero) Marshal.FreeHGlobal(attributeList);
            if (standardInput != InvalidHandle) CloseHandle(standardInput);
            if (standardError != InvalidHandle) CloseHandle(standardError);
            if (standardOutput != InvalidHandle) CloseHandle(standardOutput);
            if (job != IntPtr.Zero) CloseHandle(job);
        }
    }

    public static Room407ExportJobRun LaunchInteractive(
        string applicationName,
        string commandLine,
        string currentDirectory,
        string standardOutputPath,
        string standardErrorPath,
        long combinedByteLimit)
    {
        if (combinedByteLimit < 0)
            throw new ArgumentOutOfRangeException("combinedByteLimit", "The combined output limit cannot be negative.");

        IntPtr job = IntPtr.Zero;
        IntPtr standardOutputRead = IntPtr.Zero;
        IntPtr standardOutputWrite = IntPtr.Zero;
        IntPtr standardErrorRead = IntPtr.Zero;
        IntPtr standardErrorWrite = IntPtr.Zero;
        IntPtr standardInput = InvalidHandle;
        IntPtr attributeList = IntPtr.Zero;
        IntPtr handleList = IntPtr.Zero;
        IntPtr standardOutputDestination = InvalidHandle;
        IntPtr standardErrorDestination = InvalidHandle;
        bool attributesInitialized = false;
        bool processCreated = false;
        var processInfo = new ProcessInformation();
        try
        {
            job = CreateKillOnCloseJob();
            CreateChildOutputPipe(out standardOutputRead, out standardOutputWrite);
            CreateChildOutputPipe(out standardErrorRead, out standardErrorWrite);
            standardInput = CreateInheritedFile("NUL", GenericRead, OpenExisting);
            standardOutputDestination = CreateOutputFile(standardOutputPath);
            standardErrorDestination = CreateOutputFile(standardErrorPath);

            IntPtr attributeBytes = IntPtr.Zero;
            InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref attributeBytes);
            attributeList = Marshal.AllocHGlobal(attributeBytes);
            if (!InitializeProcThreadAttributeList(attributeList, 1, 0, ref attributeBytes))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            attributesInitialized = true;

            handleList = Marshal.AllocHGlobal(IntPtr.Size * 3);
            Marshal.WriteIntPtr(handleList, 0, standardInput);
            Marshal.WriteIntPtr(handleList, IntPtr.Size, standardOutputWrite);
            Marshal.WriteIntPtr(handleList, IntPtr.Size * 2, standardErrorWrite);
            if (!UpdateProcThreadAttribute(
                    attributeList,
                    0,
                    new IntPtr(ProcThreadAttributeHandleList),
                    handleList,
                    new IntPtr(IntPtr.Size * 3),
                    IntPtr.Zero,
                    IntPtr.Zero))
                throw new Win32Exception(Marshal.GetLastWin32Error());

            var startup = new StartupInfoEx();
            startup.Startup.Size = Marshal.SizeOf(typeof(StartupInfoEx));
            startup.Startup.Flags = (int)StartfUseStdHandles;
            startup.Startup.StandardInput = standardInput;
            startup.Startup.StandardOutput = standardOutputWrite;
            startup.Startup.StandardError = standardErrorWrite;
            startup.AttributeList = attributeList;

            if (!CreateProcessW(
                    applicationName,
                    new StringBuilder(commandLine),
                    IntPtr.Zero,
                    IntPtr.Zero,
                    true,
                    CreateSuspended | ExtendedStartupInfoPresent,
                    IntPtr.Zero,
                    currentDirectory,
                    ref startup,
                    out processInfo))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            processCreated = true;

            // The parent must not retain pipe writers: EOF then proves that the
            // assigned process tree has released every inherited writer.
            CloseHandle(standardOutputWrite);
            standardOutputWrite = IntPtr.Zero;
            CloseHandle(standardErrorWrite);
            standardErrorWrite = IntPtr.Zero;
            CloseHandle(standardInput);
            standardInput = InvalidHandle;

            uint capturedProcessId = GetRequiredProcessId(processInfo.Process);
            DateTime capturedStartedAtUtc = GetRequiredProcessStartedAtUtc(processInfo.Process);
            if (!AssignProcessToJobObject(job, processInfo.Process))
                throw new Win32Exception(Marshal.GetLastWin32Error());

            var result = new Room407ExportJobRun(
                job,
                processInfo.Process,
                capturedProcessId,
                capturedStartedAtUtc,
                combinedByteLimit,
                new OutputPumpState(standardOutputRead, standardOutputDestination),
                new OutputPumpState(standardErrorRead, standardErrorDestination));
            job = IntPtr.Zero;
            processInfo.Process = IntPtr.Zero;
            standardOutputRead = IntPtr.Zero;
            standardErrorRead = IntPtr.Zero;
            standardOutputDestination = InvalidHandle;
            standardErrorDestination = InvalidHandle;
            try
            {
                result.StartOutputPumps();
                if (ResumeThread(processInfo.Thread) == UInt32.MaxValue)
                    throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            catch
            {
                result.Dispose();
                throw;
            }

            CloseHandle(processInfo.Thread);
            processInfo.Thread = IntPtr.Zero;
            return result;
        }
        catch
        {
            if (processCreated && processInfo.Process != IntPtr.Zero)
            {
                TerminateProcess(processInfo.Process, 1);
                WaitForSingleObject(processInfo.Process, 10000);
            }
            throw;
        }
        finally
        {
            if (processInfo.Thread != IntPtr.Zero) CloseHandle(processInfo.Thread);
            if (processInfo.Process != IntPtr.Zero) CloseHandle(processInfo.Process);
            if (attributesInitialized) DeleteProcThreadAttributeList(attributeList);
            if (handleList != IntPtr.Zero) Marshal.FreeHGlobal(handleList);
            if (attributeList != IntPtr.Zero) Marshal.FreeHGlobal(attributeList);
            if (standardInput != InvalidHandle) CloseHandle(standardInput);
            if (standardErrorWrite != IntPtr.Zero) CloseHandle(standardErrorWrite);
            if (standardOutputWrite != IntPtr.Zero) CloseHandle(standardOutputWrite);
            if (standardErrorRead != IntPtr.Zero) CloseHandle(standardErrorRead);
            if (standardOutputRead != IntPtr.Zero) CloseHandle(standardOutputRead);
            if (standardErrorDestination != InvalidHandle) CloseHandle(standardErrorDestination);
            if (standardOutputDestination != InvalidHandle) CloseHandle(standardOutputDestination);
            if (job != IntPtr.Zero) CloseHandle(job);
        }
    }

    public bool WaitForExit(int milliseconds)
    {
        uint result = WaitForSingleObject(processHandle, checked((uint)milliseconds));
        if (result == WaitObject0) return true;
        if (result == WaitTimeout) return false;
        throw new Win32Exception(Marshal.GetLastWin32Error());
    }

    public bool WaitForOutputDrain(int milliseconds)
    {
        if (milliseconds < 0)
            throw new ArgumentOutOfRangeException("milliseconds", "The output-drain timeout cannot be negative.");
        if (!hasOutputPumps) return true;

        Stopwatch stopwatch = Stopwatch.StartNew();
        if (!JoinOutputPump(
                standardOutputPumpThread,
                standardOutputPumpStarted,
                milliseconds,
                stopwatch))
            return false;
        if (!JoinOutputPump(
                standardErrorPumpThread,
                standardErrorPumpStarted,
                milliseconds,
                stopwatch))
            return false;

        bool exceeded;
        lock (outputLock)
        {
            exceeded = outputLimitExceeded;
        }
        Exception failure;
        lock (stateLock)
        {
            failure = outputPumpFailure;
        }
        if (exceeded)
        {
            throw new InvalidOperationException(
                "The process exceeded the combined output limit of " +
                combinedOutputLimit.ToString(CultureInfo.InvariantCulture) +
                " bytes.");
        }
        if (failure != null)
            throw new IOException("The process output pump failed after cleanup.", failure);
        return true;
    }

    private static bool JoinOutputPump(
        Thread thread,
        bool started,
        int timeoutMilliseconds,
        Stopwatch stopwatch)
    {
        if (!started || thread == null) return true;
        if (thread == Thread.CurrentThread) return false;
        double remaining = timeoutMilliseconds - stopwatch.Elapsed.TotalMilliseconds;
        int waitMilliseconds;
        if (remaining <= 0)
            waitMilliseconds = 0;
        else if (remaining >= Int32.MaxValue)
            waitMilliseconds = Int32.MaxValue;
        else
            waitMilliseconds = (int)Math.Ceiling(remaining);
        return thread.Join(waitMilliseconds);
    }

    public int GetExitCode()
    {
        uint exitCode;
        if (!GetExitCodeProcess(processHandle, out exitCode))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        return unchecked((int)exitCode);
    }

    private uint GetActiveProcessCount()
    {
        var information = new BasicAccountingInformation();
        if (!QueryInformationJobObject(
                jobHandle,
                JobBasicAccountingInformation,
                ref information,
                (uint)Marshal.SizeOf(typeof(BasicAccountingInformation)),
                IntPtr.Zero))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        return information.ActiveProcesses;
    }

    public void TerminateTreeAndWait(int milliseconds)
    {
        if (jobHandle == IntPtr.Zero) return;
        if (!TerminateJobObject(jobHandle, 1))
            throw new Win32Exception(Marshal.GetLastWin32Error());
        DateTime deadline = DateTime.UtcNow.AddMilliseconds(milliseconds);
        while (GetActiveProcessCount() != 0)
        {
            if (DateTime.UtcNow >= deadline)
                throw new TimeoutException("The process job did not become empty before the watchdog deadline.");
            Thread.Sleep(50);
        }
    }

    public void EnsureNoDescendants(int milliseconds)
    {
        if (jobHandle != IntPtr.Zero && GetActiveProcessCount() != 0)
            TerminateTreeAndWait(milliseconds);
    }

    public void Dispose()
    {
        IntPtr job;
        IntPtr process;
        lock (stateLock)
        {
            if (disposed) return;
            disposed = true;
            job = jobHandle;
            jobHandle = IntPtr.Zero;
            process = processHandle;
            processHandle = IntPtr.Zero;
        }

        if (!hasOutputPumps)
        {
            if (job != IntPtr.Zero) CloseHandle(job);
            if (process != IntPtr.Zero) CloseHandle(process);
            return;
        }

        Stopwatch cleanupStopwatch = Stopwatch.StartNew();
        if (job != IntPtr.Zero)
        {
            try
            {
                TerminateJobObject(job, 1);
            }
            finally
            {
                // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE remains the final cleanup
                // backstop if explicit termination raced normal process exit.
                CloseHandle(job);
            }
        }
        if (process != IntPtr.Zero)
        {
            double remaining = DisposePumpGraceMilliseconds - cleanupStopwatch.Elapsed.TotalMilliseconds;
            uint waitMilliseconds = remaining <= 0 ? 0 : (uint)Math.Ceiling(remaining);
            WaitForSingleObject(process, waitMilliseconds);
        }

        // Once the kill-on-close Job is gone, every inheriting descendant has
        // released its pipe writers. Give normal draining one shared grace
        // interval, then cancel any synchronous pipe/file I/O under the same
        // overall teardown deadline.
        bool outputJoined = JoinOutputPump(
            standardOutputPumpThread,
            standardOutputPumpStarted,
            DisposePumpGraceMilliseconds,
            cleanupStopwatch);
        bool errorJoined = JoinOutputPump(
            standardErrorPumpThread,
            standardErrorPumpStarted,
            DisposePumpGraceMilliseconds,
            cleanupStopwatch);
        if (!outputJoined || !errorJoined)
        {
            CancelOutputPumpIo(standardOutputPumpState);
            CancelOutputPumpIo(standardErrorPumpState);
            if (!outputJoined)
                outputJoined = JoinOutputPump(
                    standardOutputPumpThread,
                    standardOutputPumpStarted,
                    DisposePumpForceCloseMilliseconds,
                    cleanupStopwatch);
            if (!errorJoined)
                errorJoined = JoinOutputPump(
                    standardErrorPumpThread,
                    standardErrorPumpStarted,
                    DisposePumpForceCloseMilliseconds,
                    cleanupStopwatch);
        }
        if (!outputJoined || !errorJoined)
        {
            // Cancellation should complete synchronous Windows file/pipe I/O.
            // Closing the exact remaining handles is a final bounded backstop.
            CancelOutputPumpIo(standardOutputPumpState);
            CancelOutputPumpIo(standardErrorPumpState);
            CloseOutputPumpStateNoThrow(standardOutputPumpState);
            CloseOutputPumpStateNoThrow(standardErrorPumpState);
            if (!outputJoined)
                outputJoined = JoinOutputPump(
                    standardOutputPumpThread,
                    standardOutputPumpStarted,
                    DisposeJobWaitMilliseconds,
                    cleanupStopwatch);
            if (!errorJoined)
                errorJoined = JoinOutputPump(
                    standardErrorPumpThread,
                    standardErrorPumpStarted,
                    DisposeJobWaitMilliseconds,
                    cleanupStopwatch);
        }
        CloseOutputPumpStateNoThrow(standardOutputPumpState);
        CloseOutputPumpStateNoThrow(standardErrorPumpState);
        if (process != IntPtr.Zero) CloseHandle(process);
        if (!outputJoined || !errorJoined)
            throw new TimeoutException("The process output pumps did not stop before the disposal deadline.");
    }
}
