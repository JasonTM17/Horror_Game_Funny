using System;
using System.ComponentModel;
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

    private IntPtr jobHandle;
    private IntPtr processHandle;
    private bool disposed;

    private Room407ExportJobRun(IntPtr job, IntPtr process)
    {
        jobHandle = job;
        processHandle = process;
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

    public bool WaitForExit(int milliseconds)
    {
        uint result = WaitForSingleObject(processHandle, checked((uint)milliseconds));
        if (result == WaitObject0) return true;
        if (result == WaitTimeout) return false;
        throw new Win32Exception(Marshal.GetLastWin32Error());
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
        if (disposed) return;
        disposed = true;
        if (jobHandle != IntPtr.Zero)
        {
            CloseHandle(jobHandle);
            jobHandle = IntPtr.Zero;
        }
        if (processHandle != IntPtr.Zero)
        {
            CloseHandle(processHandle);
            processHandle = IntPtr.Zero;
        }
    }
}
