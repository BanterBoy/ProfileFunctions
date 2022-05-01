function Get-CimNamespaceWithinMicrosoftWindows {
<#

.SYNOPSIS
Gets Namespace information under root/Microsoft/Windows

.DESCRIPTION
Gets Namespace information under root/Microsoft/Windows

.ROLE
Readers

#>
##SkipCheck=true##

Param(
)

import-module CimCmdlets

Get-CimInstance -Namespace root/Microsoft/Windows -Query "SELECT * FROM __NAMESPACE"

}
## [END] Get-CimNamespaceWithinMicrosoftWindows ##
function Get-CimProcess {
<#

.SYNOPSIS
Gets Msft_MTProcess objects.

.DESCRIPTION
Gets Msft_MTProcess objects.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTProcess

}
## [END] Get-CimProcess ##
function Get-ProcessDownlevel {
<#

.SYNOPSIS
Gets information about the processes running in downlevel computer.

.DESCRIPTION
Gets information about the processes running in downlevel computer.

.ROLE
Readers

#>
param
(
    [Parameter(Mandatory = $true)]
    [boolean]
    $isLocal
)

$NativeProcessInfo = @"

namespace SMT
{
    using Microsoft.Win32.SafeHandles;
    using System;
    using System.Collections.Generic;
    using System.ComponentModel;
    using System.Runtime.InteropServices;

    public class SystemProcess
    {
        public uint processId;
        public uint parentId;
        public string name;
        public string description;
        public string executablePath;
        public string userName;
        public string commandLine;
        public uint sessionId;
        public uint processStatus;
        public ulong cpuTime;
        public ulong cycleTime;
        public DateTime CreationDateTime;
        public ulong workingSetSize;
        public ulong peakWorkingSetSize;
        public ulong privateWorkingSetSize;
        public ulong sharedWorkingSetSize;
        public ulong commitCharge;
        public ulong pagedPool;
        public ulong nonPagedPool;
        public uint pageFaults;
        public uint basePriority;
        public uint handleCount;
        public uint threadCount;
        public uint userObjects;
        public uint gdiObjects;
        public ulong readOperationCount;
        public ulong writeOperationCount;
        public ulong otherOperationCount;
        public ulong readTransferCount;
        public ulong writeTransferCount;
        public ulong otherTransferCount;
        public bool elevated;
        public double cpuPercent;
        public uint operatingSystemContext;
        public uint platform;
        public double cyclePercent;
        public ushort uacVirtualization;
        public ushort dataExecutionPrevention;
        public bool isImmersive;
        public ushort intervalSeconds;
        public ushort deltaWorkingSetSize;
        public ushort deltaPageFaults;
        public bool hasChildWindow;
        public string processType;
        public string fileDescription;

        public SystemProcess(NativeMethods.SYSTEM_PROCESS_INFORMATION processInformation)
        {
            this.processId = (uint)processInformation.UniqueProcessId.ToInt32();
            this.name = Marshal.PtrToStringAuto(processInformation.ImageName.Buffer);
            this.cycleTime = processInformation.CycleTime;
            this.cpuTime = (ulong)(processInformation.KernelTime + processInformation.UserTime);
            this.sessionId = processInformation.SessionId;
            this.workingSetSize = (ulong)(processInformation.WorkingSetSize.ToInt64() / 1024);
            this.peakWorkingSetSize = (ulong)processInformation.PeakWorkingSetSize.ToInt64();
            this.privateWorkingSetSize = (ulong)processInformation.WorkingSetPrivateSize;
            this.sharedWorkingSetSize = (ulong)processInformation.WorkingSetSize.ToInt64() - this.privateWorkingSetSize;
            this.commitCharge = (ulong)processInformation.PrivatePageCount.ToInt64();
            this.pagedPool = (ulong)processInformation.QuotaPagedPoolUsage.ToInt64();
            this.nonPagedPool = (ulong)processInformation.QuotaNonPagedPoolUsage.ToInt64();
            this.pageFaults = processInformation.PageFaultCount;
            this.handleCount = processInformation.HandleCount;
            this.threadCount = processInformation.NumberOfThreads;
            this.readOperationCount = (ulong)processInformation.ReadOperationCount;
            this.writeOperationCount = (ulong)processInformation.WriteOperationCount;
            this.otherOperationCount = (ulong)processInformation.OtherOperationCount;
            this.readTransferCount = (ulong)processInformation.ReadTransferCount;
            this.writeTransferCount = (ulong)processInformation.WriteTransferCount;
            this.otherTransferCount = (ulong)processInformation.OtherTransferCount;
            this.processStatus = 0;

            if(processInformation.BasePriority <= 4)
            {
                this.basePriority = 0x00000040; //IDLE_PRIORITY_CLASS
            }
            else if (processInformation.BasePriority <= 6)
            {
                this.basePriority = 0x00004000; //BELOW_NORMAL_PRIORITY_CLASS
            }
            else if (processInformation.BasePriority <= 8)
            {
                this.basePriority = 0x00000020; //NORMAL_PRIORITY_CLASS
            }
            else if (processInformation.BasePriority <= 10)
            {
                this.basePriority = 0x00008000; //ABOVE_NORMAL_PRIORITY_CLASS
            }
            else if (processInformation.BasePriority <= 13)
            {
                this.basePriority = 0x00000080; //HIGH_PRIORITY_CLASS
            }
            else
            {
                this.basePriority = 0x00000100; //REALTIME_PRIORITY_CLASS
            }
        }
    }

    public static class NativeMethods
    {
        [StructLayout(LayoutKind.Sequential)]
        internal struct UNICODE_STRING
        {
            internal ushort Length;
            internal ushort MaximumLength;
            internal IntPtr Buffer;
        }

        [System.Runtime.InteropServices.StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_PROCESS_INFORMATION
        {
            internal uint NextEntryOffset;
            internal uint NumberOfThreads;
            internal long WorkingSetPrivateSize;
            internal uint HardFaultCount;
            internal uint NumberOfThreadsHighWatermark;
            internal ulong CycleTime;
            internal long CreateTime;
            internal long UserTime;
            internal long KernelTime;
            internal UNICODE_STRING ImageName;
            internal int BasePriority;
            internal IntPtr UniqueProcessId;
            internal IntPtr InheritedFromUniqueProcessId;
            internal uint HandleCount;
            internal uint SessionId;
            internal IntPtr UniqueProcessKey;
            internal IntPtr PeakVirtualSize;
            internal IntPtr VirtualSize;
            internal uint PageFaultCount;
            internal IntPtr PeakWorkingSetSize;
            internal IntPtr WorkingSetSize;
            internal IntPtr QuotaPeakPagedPoolUsage;
            internal IntPtr QuotaPagedPoolUsage;
            internal IntPtr QuotaPeakNonPagedPoolUsage;
            internal IntPtr QuotaNonPagedPoolUsage;
            internal IntPtr PagefileUsage;
            internal IntPtr PeakPagefileUsage;
            internal IntPtr PrivatePageCount;
            internal long ReadOperationCount;
            internal long WriteOperationCount;
            internal long OtherOperationCount;
            internal long ReadTransferCount;
            internal long WriteTransferCount;
            internal long OtherTransferCount;
        }

        public enum TOKEN_INFORMATION_CLASS
        {
            TokenElevation = 20,
            TokenVirtualizationAllowed = 23,
            TokenVirtualizationEnabled = 24
        }

        [Flags]
        public enum ProcessAccessFlags : uint
        {
            QueryInformation = 0x00000400,
            QueryLimitedInformation = 0x00001000,
        }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct TOKEN_ELEVATION
        {
            public Int32 TokenIsElevated;
        }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct UAC_ALLOWED
        {
            public Int32 UacAllowed;
        }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        public struct UAC_ENABLED
        {
            public Int32 UacEnabled;
        }

        [DllImport("ntdll.dll")]
        internal static extern int NtQuerySystemInformation(int SystemInformationClass, IntPtr SystemInformation, int SystemInformationLength, out int ReturnLength);

        [DllImport("kernel32.dll")]
        public static extern IntPtr OpenProcess(ProcessAccessFlags DesiredAccess, [MarshalAs(UnmanagedType.Bool)] bool InheritHandle, int ProcessId);

        [System.Runtime.InteropServices.DllImport("advapi32", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
        public static extern bool OpenProcessToken(IntPtr hProcess, UInt32 desiredAccess, out Microsoft.Win32.SafeHandles.SafeWaitHandle hToken);

        [System.Runtime.InteropServices.DllImport("advapi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
        [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
        public static extern bool GetTokenInformation(SafeWaitHandle hToken, TOKEN_INFORMATION_CLASS tokenInfoClass, IntPtr pTokenInfo, Int32 tokenInfoLength, out Int32 returnLength);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern uint GetGuiResources(IntPtr hProcess, uint uiFlags);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr hObject);

        internal const int SystemProcessInformation = 5;

        internal const int STATUS_INFO_LENGTH_MISMATCH = unchecked((int)0xC0000004);

        internal const uint TOKEN_QUERY = 0x0008;
    }

    public static class Process
    {
        public static IEnumerable<SystemProcess> Enumerate()
        {
            List<SystemProcess> process = new List<SystemProcess>();

            int bufferSize = 1024;

            IntPtr buffer = Marshal.AllocHGlobal(bufferSize);

            QuerySystemProcessInformation(ref buffer, ref bufferSize);

            long totalOffset = 0;

            while (true)
            {
                IntPtr currentPtr = (IntPtr)((long)buffer + totalOffset);

                NativeMethods.SYSTEM_PROCESS_INFORMATION pi = new NativeMethods.SYSTEM_PROCESS_INFORMATION();

                pi = (NativeMethods.SYSTEM_PROCESS_INFORMATION)Marshal.PtrToStructure(currentPtr, typeof(NativeMethods.SYSTEM_PROCESS_INFORMATION));

                process.Add(new SystemProcess(pi));

                if (pi.NextEntryOffset == 0)
                {
                    break;
                }

                totalOffset += pi.NextEntryOffset;
            }

            Marshal.FreeHGlobal(buffer);

            GetExtendedProcessInfo(process);

            return process;
        }

        private static void GetExtendedProcessInfo(List<SystemProcess> processes)
        {
            foreach(var process in processes)
            {
                IntPtr hProcess = GetProcessHandle(process);

                if(hProcess != IntPtr.Zero)
                {
                    try
                    {
                        process.elevated = IsElevated(hProcess);
                        process.userObjects = GetCountUserResources(hProcess);
                        process.gdiObjects = GetCountGdiResources(hProcess);
                        process.uacVirtualization = GetVirtualizationStatus(hProcess);
                    }
                    finally
                    {
                        NativeMethods.CloseHandle(hProcess);
                    }
                }
            }
        }

        private static uint GetCountGdiResources(IntPtr hProcess)
        {
            return NativeMethods.GetGuiResources(hProcess, 0);
        }
        private static uint GetCountUserResources(IntPtr hProcess)
        {
            return NativeMethods.GetGuiResources(hProcess, 1);
        }

        private static ushort GetVirtualizationStatus(IntPtr hProcess)
        {
            /* Virtualization status:
             * 0: Unknown
             * 1: Disabled
             * 2: Enabled
             * 3: Not Allowed
             */
            ushort virtualizationStatus = 0;

            try
            {
                if(!IsVirtualizationAllowed(hProcess))
                {
                    virtualizationStatus = 3;
                }
                else
                {
                    if(IsVirtualizationEnabled(hProcess))
                    {
                        virtualizationStatus = 2;
                    }
                    else
                    {
                        virtualizationStatus = 1;
                    }
                }
            }
            catch(Win32Exception)
            {
            }

            return virtualizationStatus;
        }

        private static bool IsVirtualizationAllowed(IntPtr hProcess)
        {
            bool uacVirtualizationAllowed = false;

            Microsoft.Win32.SafeHandles.SafeWaitHandle hToken = null;
            int cbUacAlowed = 0;
            IntPtr pUacAllowed = IntPtr.Zero;

            try
            {
                if (!NativeMethods.OpenProcessToken(hProcess, NativeMethods.TOKEN_QUERY, out hToken))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                cbUacAlowed = System.Runtime.InteropServices.Marshal.SizeOf(typeof(NativeMethods.UAC_ALLOWED));
                pUacAllowed = System.Runtime.InteropServices.Marshal.AllocHGlobal(cbUacAlowed);

                if (pUacAllowed == IntPtr.Zero)
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                if (!NativeMethods.GetTokenInformation(hToken, NativeMethods.TOKEN_INFORMATION_CLASS.TokenVirtualizationAllowed, pUacAllowed, cbUacAlowed, out cbUacAlowed))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                NativeMethods.UAC_ALLOWED uacAllowed = (NativeMethods.UAC_ALLOWED)System.Runtime.InteropServices.Marshal.PtrToStructure(pUacAllowed, typeof(NativeMethods.UAC_ALLOWED));

                uacVirtualizationAllowed = (uacAllowed.UacAllowed != 0);
            }
            finally
            {
                if (hToken != null)
                {
                    hToken.Close();
                    hToken = null;
                }

                if (pUacAllowed != IntPtr.Zero)
                {
                    System.Runtime.InteropServices.Marshal.FreeHGlobal(pUacAllowed);
                    pUacAllowed = IntPtr.Zero;
                    cbUacAlowed = 0;
                }
            }

            return uacVirtualizationAllowed;
        }

        public static bool IsVirtualizationEnabled(IntPtr hProcess)
        {
            bool uacVirtualizationEnabled = false;

            Microsoft.Win32.SafeHandles.SafeWaitHandle hToken = null;
            int cbUacEnabled = 0;
            IntPtr pUacEnabled = IntPtr.Zero;

            try
            {
                if (!NativeMethods.OpenProcessToken(hProcess, NativeMethods.TOKEN_QUERY, out hToken))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                cbUacEnabled = System.Runtime.InteropServices.Marshal.SizeOf(typeof(NativeMethods.UAC_ENABLED));
                pUacEnabled = System.Runtime.InteropServices.Marshal.AllocHGlobal(cbUacEnabled);

                if (pUacEnabled == IntPtr.Zero)
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                if (!NativeMethods.GetTokenInformation(hToken, NativeMethods.TOKEN_INFORMATION_CLASS.TokenVirtualizationEnabled, pUacEnabled, cbUacEnabled, out cbUacEnabled))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                NativeMethods.UAC_ENABLED uacEnabled = (NativeMethods.UAC_ENABLED)System.Runtime.InteropServices.Marshal.PtrToStructure(pUacEnabled, typeof(NativeMethods.UAC_ENABLED));

                uacVirtualizationEnabled = (uacEnabled.UacEnabled != 0);
            }
            finally
            {
                if (hToken != null)
                {
                    hToken.Close();
                    hToken = null;
                }

                if (pUacEnabled != IntPtr.Zero)
                {
                    System.Runtime.InteropServices.Marshal.FreeHGlobal(pUacEnabled);
                    pUacEnabled = IntPtr.Zero;
                    cbUacEnabled = 0;
                }
            }

            return uacVirtualizationEnabled;
        }

        private static bool IsElevated(IntPtr hProcess)
        {
             bool fIsElevated = false;
            Microsoft.Win32.SafeHandles.SafeWaitHandle hToken = null;
            int cbTokenElevation = 0;
            IntPtr pTokenElevation = IntPtr.Zero;

            try
            {
                if (!NativeMethods.OpenProcessToken(hProcess, NativeMethods.TOKEN_QUERY, out hToken))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                cbTokenElevation = System.Runtime.InteropServices.Marshal.SizeOf(typeof(NativeMethods.TOKEN_ELEVATION));
                pTokenElevation = System.Runtime.InteropServices.Marshal.AllocHGlobal(cbTokenElevation);

                if (pTokenElevation == IntPtr.Zero)
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                if (!NativeMethods.GetTokenInformation(hToken, NativeMethods.TOKEN_INFORMATION_CLASS.TokenElevation, pTokenElevation, cbTokenElevation, out cbTokenElevation))
                {
                    throw new Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
                }

                NativeMethods.TOKEN_ELEVATION elevation = (NativeMethods.TOKEN_ELEVATION)System.Runtime.InteropServices.Marshal.PtrToStructure(pTokenElevation, typeof(NativeMethods.TOKEN_ELEVATION));

                fIsElevated = (elevation.TokenIsElevated != 0);
            }
            catch (Win32Exception)
            {
            }
            finally
            {
                if (hToken != null)
                {
                    hToken.Close();
                    hToken = null;
                }

                if (pTokenElevation != IntPtr.Zero)
                {
                    System.Runtime.InteropServices.Marshal.FreeHGlobal(pTokenElevation);
                    pTokenElevation = IntPtr.Zero;
                    cbTokenElevation = 0;
                }
            }

            return fIsElevated;
        }

        private static IntPtr GetProcessHandle(SystemProcess process)
        {
            IntPtr hProcess = NativeMethods.OpenProcess(NativeMethods.ProcessAccessFlags.QueryInformation | NativeMethods.ProcessAccessFlags.QueryLimitedInformation, false, (int)process.processId);

            if(hProcess == IntPtr.Zero)
            {
                hProcess = NativeMethods.OpenProcess(NativeMethods.ProcessAccessFlags.QueryLimitedInformation, false, (int)process.processId);
            }

            return hProcess;
        }

        private static void QuerySystemProcessInformation(ref IntPtr processInformationBuffer, ref int processInformationBufferSize)
        {
            const int maxTries = 10;
            bool success = false;

            for (int i = 0; i < maxTries; i++)
            {
                int sizeNeeded;

                int result = NativeMethods.NtQuerySystemInformation(NativeMethods.SystemProcessInformation, processInformationBuffer, processInformationBufferSize, out sizeNeeded);

                if (result == NativeMethods.STATUS_INFO_LENGTH_MISMATCH)
                {
                    if (processInformationBuffer != IntPtr.Zero)
                    {
                        Marshal.FreeHGlobal(processInformationBuffer);
                    }

                    processInformationBuffer = Marshal.AllocHGlobal(sizeNeeded);
                    processInformationBufferSize = sizeNeeded;
                }

                else if (result < 0)
                {
                    throw new Exception(String.Format("NtQuerySystemInformation failed with code 0x{0:X8}", result));
                }

                else
                {
                    success = true;
                    break;
                }
            }

            if (!success)
            {
                throw new Exception("Failed to allocate enough memory for NtQuerySystemInformation");
            }
        }
    }
}
"@

############################################################################################################################

# Global settings for the script.

############################################################################################################################

$ErrorActionPreference = "Stop"

Set-StrictMode -Version 3.0

############################################################################################################################

# Helper functions.

############################################################################################################################

function Get-ProcessListFromWmi {
    <#
    .Synopsis
        Name: Get-ProcessListFromWmi
        Description: Runs the WMI command to get Win32_Process objects and returns them in hashtable where key is processId.

    .Returns
        The list of processes in the form of hashtable.
    #>
    $processList = @{}

    $WmiProcessList = Get-WmiObject -Class Win32_Process

    foreach ($process in $WmiProcessList) {
        $processList.Add([int]$process.ProcessId, $process)
    }

    $processList
}

function Get-ProcessPerfListFromWmi {
    <#
    .Synopsis
        Name: Get-ProcessPerfListFromWmi
        Description: Runs the WMI command to get Win32_PerfFormattedData_PerfProc_Process objects and returns them in hashtable where key is processId.

    .Returns
        The list of processes performance data in the form of hashtable.
    #>
    $processPerfList = @{}

    $WmiProcessPerfList = Get-WmiObject -Class Win32_PerfFormattedData_PerfProc_Process

    foreach ($process in $WmiProcessPerfList) {
        try {
            $processPerfList.Add([int]$process.IdProcess, $process)
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq 'ArgumentException') {
                $processPerfList.Remove([int]$process.IdProcess)
            }

            $processPerfList.Add([int]$process.IdProcess, $process)
        }
    }

    $processPerfList
}

function Get-ProcessListFromPowerShell {
    <#
    .Synopsis
        Name: Get-ProcessListFromPowerShell
        Description: Runs the PowerShell command Get-Process to get process objects.

    .Returns
        The list of processes in the form of hashtable.
    #>
    $processList = @{}

    if ($psVersionTable.psversion.Major -ge 4) {
        #
        # It will crash to run 'Get-Process' with parameter 'IncludeUserName' multiple times in a session.
        # Currently the UI will not reuse the session as a workaround.
        # We need to remove the paramter 'IncludeUserName' if this issue happens again.
        #
        $PowerShellProcessList = Get-Process -IncludeUserName -ErrorAction SilentlyContinue
    }
    else {
        $PowerShellProcessList = Get-Process -ErrorAction SilentlyContinue
    }

    foreach ($process in $PowerShellProcessList) {
        $processList.Add([int]$process.Id, $process)
    }

    $processList
}

function Get-LocalSystemAccount {
    <#
    .Synopsis
        Name: Get-LocalSystemAccount
        Description: Gets the name of local system account.

    .Returns
        The name local system account.
    #>
    $sidLocalSystemAccount = "S-1-5-18"

    $objSID = New-Object System.Security.Principal.SecurityIdentifier($sidLocalSystemAccount)

    $objSID.Translate( [System.Security.Principal.NTAccount]).Value
}

function Get-NumberOfLogicalProcessors {
    <#
    .Synopsis
        Name: Get-NumberOfLogicalProcessors
        Description: Gets the number of logical processors on the system.

    .Returns
        The number of logical processors on the system.
    #>
    $computerSystem = Get-CimInstance -Class Win32_ComputerSystem -Property NumberOfLogicalProcessors -ErrorAction Stop
    if ($computerSystem) {
        $computerSystem.NumberOfLogicalProcessors
    }
    else {
        throw 'Unable to get processor information'
    }
}


############################################################################################################################
# Main script.
############################################################################################################################

Add-Type -TypeDefinition $NativeProcessInfo
Remove-Variable NativeProcessInfo

try {
    #
    # Get the information about system processes from different sources.
    #
    $NumberOfLogicalProcessors = Get-NumberOfLogicalProcessors
    $NativeProcesses = [SMT.Process]::Enumerate()
    $WmiProcesses = Get-ProcessListFromWmi
    $WmiPerfProcesses = Get-ProcessPerfListFromWmi
    $PowerShellProcesses = Get-ProcessListFromPowerShell
    $LocalSystemAccount = Get-LocalSystemAccount

    $systemIdleProcess = $null
    $cpuInUse = 0

    # process paths and categorization taken from Task Manager
    # https://microsoft.visualstudio.com/_git/os?path=%2Fbase%2Fdiagnosis%2Fpdui%2Fatm%2FApplications.cpp&version=GBofficial%2Frs_fun_flight&_a=contents&line=44&lineStyle=plain&lineEnd=59&lineStartColumn=1&lineEndColumn=3
    $criticalProcesses = (
        "$($env:windir)\system32\winlogon.exe",
        "$($env:windir)\system32\wininit.exe",
        "$($env:windir)\system32\csrss.exe",
        "$($env:windir)\system32\lsass.exe",
        "$($env:windir)\system32\smss.exe",
        "$($env:windir)\system32\services.exe",
        "$($env:windir)\system32\taskeng.exe",
        "$($env:windir)\system32\taskhost.exe",
        "$($env:windir)\system32\dwm.exe",
        "$($env:windir)\system32\conhost.exe",
        "$($env:windir)\system32\svchost.exe",
        "$($env:windir)\system32\sihost.exe",
        "$($env:ProgramFiles)\Windows Defender\msmpeng.exe",
        "$($env:ProgramFiles)\Windows Defender\nissrv.exe",
        "$($env:windir)\explorer.exe"
    )

    $sidebarPath = "$($end:ProgramFiles)\Windows Sidebar\sidebar.exe"
    $appFrameHostPath = "$($env:windir)\system32\ApplicationFrameHost.exe"

    $edgeProcesses = (
        "$($env:windir)\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe",
        "$($env:windir)\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdgeCP.exe",
        "$($env:windir)\system32\browser_broker.exe"
    )

    #
    # Extract the additional process related information and fill up each nativeProcess object.
    #
    foreach ($nativeProcess in $NativeProcesses) {
        $WmiProcess = $null
        $WmiPerfProcess = $null
        $psProcess = $null

        # Same process as retrieved from WMI call Win32_Process
        if ($WmiProcesses.ContainsKey([int]$nativeProcess.ProcessId)) {
            $WmiProcess = $WmiProcesses.Get_Item([int]$nativeProcess.ProcessId)
        }

        # Same process as retrieved from WMI call Win32_PerfFormattedData_PerfProc_Process
        if ($WmiPerfProcesses.ContainsKey([int]$nativeProcess.ProcessId)) {
            $WmiPerfProcess = $WmiPerfProcesses.Get_Item([int]$nativeProcess.ProcessId)
        }

        # Same process as retrieved from PowerShell call Win32_Process
        if ($PowerShellProcesses.ContainsKey([int]$nativeProcess.ProcessId)) {
            $psProcess = $PowerShellProcesses.Get_Item([int]$nativeProcess.ProcessId)
        }

        if (($WmiProcess -eq $null) -or ($WmiPerfProcess -eq $null) -or ($psProcess -eq $null)) {continue}

        $nativeProcess.name = $WmiProcess.Name
        $nativeProcess.description = $WmiProcess.Description
        $nativeProcess.executablePath = $WmiProcess.ExecutablePath
        $nativeProcess.commandLine = $WmiProcess.CommandLine
        $nativeProcess.parentId = $WmiProcess.ParentProcessId

        #
        # Process CPU utilization and divide by number of cores
        # Win32_PerfFormattedData_PerfProc_Process PercentProcessorTime has a max number of 100 * cores so we want to normalize it
        #
        if ($WmiPerfProcess -and $WmiPerfProcess.PercentProcessorTime -ne $null -and $NumberOfLogicalProcessors -gt 0) {
            $nativeProcess.cpuPercent = $WmiPerfProcess.PercentProcessorTime / $NumberOfLogicalProcessors
        }
        #
        # Process start time.
        #
        if ($WmiProcess.CreationDate) {
            $nativeProcess.CreationDateTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($WmiProcess.CreationDate)
        }
        else {
            if ($nativeProcess.ProcessId -in @(0, 4)) {
                # Under some circumstances, the process creation time is not available for processs "System Idle Process" or "System"
                # In this case we assume that the process creation time is when the system was last booted.
                $nativeProcess.CreationDateTime = [System.Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject -Class win32_Operatingsystem).LastBootUpTime)
            }
        }

        #
        # Owner of the process.
        #
        if ($psVersionTable.psversion.Major -ge 4) {
            $nativeProcess.userName = $psProcess.UserName
        }

        # If UserName was not present available in results returned from Get-Process, then get the UserName from WMI class Get-Process
        <#
        ###### GetOwner is too slow so skip this part. ####

        if([string]::IsNullOrWhiteSpace($nativeProcess.userName))
        {
            $processOwner = Invoke-WmiMethod -InputObject $WmiProcess -Name GetOwner -ErrorAction SilentlyContinue

            try
            {
                if($processOwner.Domain)
                {
                    $nativeProcess.userName = "{0}\{1}" -f $processOwner.Domain, $processOwner.User
                }
                else
                {
                    $nativeProcess.userName = "{0}" -f $processOwner.User
                }
            }
            catch
            {
            }

            #In case of 'System Idle Process" and 'System' there is a need to explicitly mention NT Authority\System as Process Owner.
            if([string]::IsNullOrWhiteSpace($nativeProcess.userName) -and $nativeProcess.processId -in @(0, 4))
            {
                   $nativeProcess.userName = Get-LocalSystemAccount
            }
        }
        #>

        #In case of 'System Idle Process" and 'System' there is a need to explicitly mention NT Authority\System as Process Owner.
        if ([string]::IsNullOrWhiteSpace($nativeProcess.userName) -and $nativeProcess.processId -in @(0, 4)) {
            $nativeProcess.userName = $LocalSystemAccount
        }

        #
        # The process status ( i.e. running or suspended )
        #
        $countSuspendedThreads = @($psProcess.Threads | Where-Object { $_.WaitReason -eq [System.Diagnostics.ThreadWaitReason]::Suspended }).Count

        if ($psProcess.Threads.Count -eq $countSuspendedThreads) {
            $nativeProcess.ProcessStatus = 2
        }
        else {
            $nativeProcess.ProcessStatus = 1
        }

        # calculate system idle process
        if ($nativeProcess.processId -eq 0) {
            $systemIdleProcess = $nativeProcess
        }
        else {
            $cpuInUse += $nativeProcess.cpuPercent
        }


        if ($isLocal) {
            $nativeProcess.hasChildWindow = $psProcess -ne $null -and $psProcess.MainWindowHandle -ne 0

            if ($psProcess.MainModule -and $psProcess.MainModule.FileVersionInfo) {
                $nativeProcess.fileDescription = $psProcess.MainModule.FileVersionInfo.FileDescription
            }

            if ($edgeProcesses -contains $nativeProcess.executablePath) {
                # special handling for microsoft edge used by task manager
                # group all edge processes into applications
                $nativeProcess.fileDescription = 'Microsoft Edge'
                $nativeProcess.processType = 'application'
            }
            elseif ($criticalProcesses -contains $nativeProcess.executablePath `
                    -or (($nativeProcess.executablePath -eq $null -or $nativeProcess.executablePath -eq '') -and $null -ne ($criticalProcesses | Where-Object {$_ -match $nativeProcess.name})) ) {
                # process is windows if its executable path is a critical process, defined by Task Manager
                # if the process has no executable path recorded, fallback to use the name to match to critical process
                $nativeProcess.processType = 'windows'
            }
            elseif (($nativeProcess.hasChildWindow -and $nativeProcess.executablePath -ne $appFrameHostPath) -or $nativeProcess.executablePath -eq $sidebarPath) {
                # sidebar.exe, or has child window (excluding ApplicationFrameHost.exe)
                $nativeProcess.processType = 'application'
            }
            else {
                $nativeProcess.processType = 'background'
            }
        }
    }

    if ($systemIdleProcess -ne $null) {
        $systemIdleProcess.cpuPercent = [Math]::Max(100 - $cpuInUse, 0)
    }

}
catch {
    throw $_
}
finally {
    $WmiProcesses = $null
    $WmiPerfProcesses = $null
}

# Return the result to the caller of this script.
$NativeProcesses


}
## [END] Get-ProcessDownlevel ##
function Get-ProcessHandle {
<#

.SYNOPSIS
Gets the filtered information of all the Operating System handles.

.DESCRIPTION
Gets the filtered information of all the Operating System handles.

.ROLE
Readers

#>

param (
    [Parameter(Mandatory = $true, ParameterSetName = 'processId')]
    [int]
    $processId,

    [Parameter(Mandatory = $true, ParameterSetName = 'handleSubstring')]
    [string]
    $handleSubstring
)

$SystemHandlesInfo = @"
    
namespace SME
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Globalization;
    using System.IO;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Threading;

    public static class NativeMethods
    {
        internal enum SYSTEM_INFORMATION_CLASS : int
        {
            /// </summary>
            SystemHandleInformation = 16
        }

        [Flags]
        internal enum ProcessAccessFlags : int
        {
            All = 0x001F0FFF,
            Terminate = 0x00000001,
            CreateThread = 0x00000002,
            VMOperation = 0x00000008,
            VMRead = 0x00000010,
            VMWrite = 0x00000020,
            DupHandle = 0x00000040,
            SetInformation = 0x00000200,
            QueryInformation = 0x00000400,
            QueryLimitedInformation = 0x00001000,
            Synchronize = 0x00100000
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct SystemHandle
        {
            public Int32 ProcessId;
            public Byte ObjectTypeNumber;
            public Byte Flags;
            public UInt16 Handle;
            public IntPtr Object;
            public Int32 GrantedAccess;
        }

        [Flags]
        public enum DuplicateOptions : int
        {
            NONE = 0,
            /// <summary>
            /// Closes the source handle. This occurs regardless of any error status returned.
            /// </summary>
            DUPLICATE_CLOSE_SOURCE = 0x00000001,
            /// <summary>
            /// Ignores the dwDesiredAccess parameter. The duplicate handle has the same access as the source handle.
            /// </summary>
            DUPLICATE_SAME_ACCESS = 0x00000002
        }

        internal enum OBJECT_INFORMATION_CLASS : int
        {
            /// <summary>
            /// Returns a PUBLIC_OBJECT_BASIC_INFORMATION structure as shown in the following Remarks section.
            /// </summary>
            ObjectBasicInformation = 0,
            ObjectNameInformation = 1,
            /// <summary>
            /// Returns a PUBLIC_OBJECT_TYPE_INFORMATION structure as shown in the following Remarks section.
            /// </summary>
            ObjectTypeInformation = 2
        }

        public enum FileType : int
        {
            FileTypeChar = 0x0002,
            FileTypeDisk = 0x0001,
            FileTypePipe = 0x0003,
            FileTypeRemote = 0x8000,
            FileTypeUnknown = 0x0000,
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct GENERIC_MAPPING
        {
            UInt32 GenericRead;
            UInt32 GenericWrite;
            UInt32 GenericExecute;
            UInt32 GenericAll;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct OBJECT_TYPE_INFORMATION
        {
            public UNICODE_STRING TypeName;
            public UInt32 TotalNumberOfObjects;
            public UInt32 TotalNumberOfHandles;
            public UInt32 TotalPagedPoolUsage;
            public UInt32 TotalNonPagedPoolUsage;
            public UInt32 TotalNamePoolUsage;
            public UInt32 TotalHandleTableUsage;
            public UInt32 HighWaterNumberOfObjects;
            public UInt32 HighWaterNumberOfHandles;
            public UInt32 HighWaterPagedPoolUsage;
            public UInt32 HighWaterNonPagedPoolUsage;
            public UInt32 HighWaterNamePoolUsage;
            public UInt32 HighWaterHandleTableUsage;
            public UInt32 InvalidAttributes;
            public GENERIC_MAPPING GenericMapping;
            public UInt32 ValidAccessMask;
            public Boolean SecurityRequired;
            public Boolean MaintainHandleCount;
            public UInt32 PoolType;
            public UInt32 DefaultPagedPoolCharge;
            public UInt32 DefaultNonPagedPoolCharge;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct UNICODE_STRING
        {
            public UInt16 Length;
            public UInt16 MaximumLength;
            [MarshalAs(UnmanagedType.LPWStr)]
            public String Buffer;
        }

        [DllImport("ntdll.dll")]
        internal static extern Int32 NtQuerySystemInformation(
            SYSTEM_INFORMATION_CLASS SystemInformationClass,
            IntPtr SystemInformation,
            Int32 SystemInformationLength,
            out Int32 ReturnedLength);

        [DllImport("kernel32.dll")]
        internal static extern IntPtr OpenProcess(
            ProcessAccessFlags dwDesiredAccess,
            [MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            Int32 dwProcessId);

        [DllImport("ntdll.dll")]
        internal static extern UInt32 NtQueryObject(
            Int32 Handle,
            OBJECT_INFORMATION_CLASS ObjectInformationClass,
            IntPtr ObjectInformation,
            Int32 ObjectInformationLength,
            out Int32 ReturnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool DuplicateHandle(
            IntPtr hSourceProcessHandle,
            IntPtr hSourceHandle,
            IntPtr hTargetProcessHandle,
            out IntPtr lpTargetHandle,
            UInt32 dwDesiredAccess,
            [MarshalAs(UnmanagedType.Bool)]
            bool bInheritHandle,
            DuplicateOptions dwOptions);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool QueryFullProcessImageName([In]IntPtr hProcess, [In]Int32 dwFlags, [Out]StringBuilder exeName, ref Int32 size);

        [DllImport("psapi.dll")]
        public static extern UInt32 GetModuleBaseName(IntPtr hProcess, IntPtr hModule, StringBuilder baseName, UInt32 size);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern UInt32 QueryDosDevice(String lpDeviceName, System.Text.StringBuilder lpTargetPath, Int32 ucchMax);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern FileType GetFileType(IntPtr hFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool CloseHandle(IntPtr hObject);

        internal const Int32 STATUS_INFO_LENGTH_MISMATCH = unchecked((Int32)0xC0000004L);
        internal const Int32 STATUS_SUCCESS = 0x00000000;
    }

    public class SystemHandles
    {
        private Queue<SystemHandle> systemHandles;
        private Int32 processId;
        String fileNameToMatch;
        Dictionary<Int32, IntPtr> processIdToHandle;
        Dictionary<Int32, String> processIdToImageName;
        private const Int32 GetObjectNameTimeoutMillis = 50;
        private Thread backgroundWorker;
        private static object syncRoot = new Object();

        public static IEnumerable<SystemHandle> EnumerateAllSystemHandles()
        {
            SystemHandles systemHandles = new SystemHandles();

            return systemHandles.Enumerate(HandlesEnumerationScope.AllSystemHandles);
        }
        public static IEnumerable<SystemHandle> EnumerateProcessSpecificHandles(Int32 processId)
        {
            SystemHandles systemHandles = new SystemHandles(processId);

            return systemHandles.Enumerate(HandlesEnumerationScope.ProcessSpecificHandles);
        }

        public static IEnumerable<SystemHandle> EnumerateMatchingFileNameHandles(String fileNameToMatch)
        {
            SystemHandles systemHandles = new SystemHandles(fileNameToMatch);

            return systemHandles.Enumerate(HandlesEnumerationScope.MatchingFileNameHandles);
        }

        private SystemHandles()
        { }

        public SystemHandles(Int32 processId)
        {
            this.processId = processId;
        }

        public SystemHandles(String fileNameToMatch)
        {
            this.fileNameToMatch = fileNameToMatch;
        }

        public IEnumerable<SystemHandle> Enumerate(HandlesEnumerationScope handlesEnumerationScope)
        {
            IEnumerable<SystemHandle> handles = null;

            this.backgroundWorker = new Thread(() => handles = Enumerate_Internal(handlesEnumerationScope));

            this.backgroundWorker.IsBackground = true;

            this.backgroundWorker.Start();

            return handles;
        }

        public bool IsBusy
        {
            get
            {
                return this.backgroundWorker.IsAlive;
            }
        }

        public bool WaitForEnumerationToComplete(int timeoutMillis)
        {
            return this.backgroundWorker.Join(timeoutMillis);
        }

        private IEnumerable<SystemHandle> Enumerate_Internal(HandlesEnumerationScope handlesEnumerationScope)
        {
            Int32 result;
            Int32 bufferLength = 1024;
            IntPtr buffer = Marshal.AllocHGlobal(bufferLength);
            Int32 requiredLength;
            Int64 handleCount;
            Int32 offset = 0;
            IntPtr currentHandlePtr = IntPtr.Zero;
            NativeMethods.SystemHandle systemHandleStruct;
            Int32 systemHandleStructSize = 0;
            this.systemHandles = new Queue<SystemHandle>();
            this.processIdToHandle = new Dictionary<Int32, IntPtr>();
            this.processIdToImageName = new Dictionary<Int32, String>();

            while (true)
            {
                result = NativeMethods.NtQuerySystemInformation(
                    NativeMethods.SYSTEM_INFORMATION_CLASS.SystemHandleInformation,
                    buffer,
                    bufferLength,
                    out requiredLength);

                if (result == NativeMethods.STATUS_SUCCESS)
                {
                    break;
                }
                else if (result == NativeMethods.STATUS_INFO_LENGTH_MISMATCH)
                {
                    Marshal.FreeHGlobal(buffer);
                    bufferLength *= 2;
                    buffer = Marshal.AllocHGlobal(bufferLength);
                }
                else
                {
                    throw new InvalidOperationException(
                        String.Format(CultureInfo.InvariantCulture, "NtQuerySystemInformation failed with error code {0}", result));
                }
            } // End while loop.

            if (IntPtr.Size == 4)
            {
                handleCount = Marshal.ReadInt32(buffer);
            }
            else
            {
                handleCount = Marshal.ReadInt64(buffer);
            }

            offset = IntPtr.Size;
            systemHandleStruct = new NativeMethods.SystemHandle();
            systemHandleStructSize = Marshal.SizeOf(systemHandleStruct);

            if (handlesEnumerationScope == HandlesEnumerationScope.AllSystemHandles)
            {
                EnumerateAllSystemHandles(buffer, offset, systemHandleStructSize, handleCount);
            }
            else if (handlesEnumerationScope == HandlesEnumerationScope.ProcessSpecificHandles)
            {
                EnumerateProcessSpecificSystemHandles(buffer, offset, systemHandleStructSize, handleCount);
            }
            else if (handlesEnumerationScope == HandlesEnumerationScope.MatchingFileNameHandles)
            {
                this.EnumerateMatchingFileNameHandles(buffer, offset, systemHandleStructSize, handleCount);
            }

            if (buffer != IntPtr.Zero)
            {
                Marshal.FreeHGlobal(buffer);
            }

            this.Cleanup();

            return this.systemHandles;
        }

        public IEnumerable<SystemHandle> ExtractResults()
        {
            lock (syncRoot)
            {
                while (this.systemHandles.Count > 0)
                {
                    yield return this.systemHandles.Dequeue();
                }
            }
        }

        private void EnumerateAllSystemHandles(IntPtr buffer, Int32 offset, Int32 systemHandleStructSize, Int64 handleCount)
        {
            for (Int64 i = 0; i < handleCount; i++)
            {
                NativeMethods.SystemHandle currentHandleInfo =
                        (NativeMethods.SystemHandle)Marshal.PtrToStructure((IntPtr)((Int64)buffer + offset), typeof(NativeMethods.SystemHandle));

                ExamineCurrentHandle(currentHandleInfo);

                offset += systemHandleStructSize;
            }
        }

        private void EnumerateProcessSpecificSystemHandles(IntPtr buffer, Int32 offset, Int32 systemHandleStructSize, Int64 handleCount)
        {
            for (Int64 i = 0; i < handleCount; i++)
            {
                NativeMethods.SystemHandle currentHandleInfo =
                        (NativeMethods.SystemHandle)Marshal.PtrToStructure((IntPtr)((Int64)buffer + offset), typeof(NativeMethods.SystemHandle));

                if (currentHandleInfo.ProcessId == this.processId)
                {
                    ExamineCurrentHandle(currentHandleInfo);
                }

                offset += systemHandleStructSize;
            }
        }

        private void EnumerateMatchingFileNameHandles(IntPtr buffer, Int32 offset, Int32 systemHandleStructSize, Int64 handleCount)
        {
            for (Int64 i = 0; i < handleCount; i++)
            {
                NativeMethods.SystemHandle currentHandleInfo =
                        (NativeMethods.SystemHandle)Marshal.PtrToStructure((IntPtr)((Int64)buffer + offset), typeof(NativeMethods.SystemHandle));

                ExamineCurrentHandleForForMatchingFileName(currentHandleInfo, this.fileNameToMatch);

                offset += systemHandleStructSize;
            }
        }

        private void ExamineCurrentHandle(
            NativeMethods.SystemHandle currentHandleInfo)
        {
            IntPtr sourceProcessHandle = this.GetProcessHandle(currentHandleInfo.ProcessId);

            if (sourceProcessHandle == IntPtr.Zero)
            {
                return;
            }

            String processImageName = this.GetProcessImageName(currentHandleInfo.ProcessId, sourceProcessHandle);

            IntPtr duplicateHandle = CreateDuplicateHandle(sourceProcessHandle, (IntPtr)currentHandleInfo.Handle);

            if (duplicateHandle == IntPtr.Zero)
            {
                return;
            }

            String objectType = GetObjectType(duplicateHandle);

            String objectName = String.Empty;

            if (objectType != "File")
            {
                objectName = GetObjectName(duplicateHandle);
            }
            else
            {
                Thread getObjectNameThread = new Thread(() => objectName = GetObjectName(duplicateHandle));
                getObjectNameThread.IsBackground = true;
                getObjectNameThread.Start();

                if (false == getObjectNameThread.Join(GetObjectNameTimeoutMillis))
                {
                    getObjectNameThread.Abort();

                    getObjectNameThread.Join(GetObjectNameTimeoutMillis);

                    objectName = String.Empty;
                }
                else
                {
                    objectName = GetRegularFileName(objectName);
                }

                getObjectNameThread = null;
            }

            if (!String.IsNullOrWhiteSpace(objectType) &&
                !String.IsNullOrWhiteSpace(objectName))
            {
                SystemHandle systemHandle = new SystemHandle();
                systemHandle.TypeName = objectType;
                systemHandle.Name = objectName;
                systemHandle.ObjectTypeNumber = currentHandleInfo.ObjectTypeNumber;
                systemHandle.ProcessId = currentHandleInfo.ProcessId;
                systemHandle.ProcessImageName = processImageName;

                RegisterHandle(systemHandle);
            }

            NativeMethods.CloseHandle(duplicateHandle);
        }

        private void ExamineCurrentHandleForForMatchingFileName(
             NativeMethods.SystemHandle currentHandleInfo, String fileNameToMatch)
        {
            IntPtr sourceProcessHandle = this.GetProcessHandle(currentHandleInfo.ProcessId);

            if (sourceProcessHandle == IntPtr.Zero)
            {
                return;
            }

            String processImageName = this.GetProcessImageName(currentHandleInfo.ProcessId, sourceProcessHandle);

            if (String.IsNullOrWhiteSpace(processImageName))
            {
                return;
            }

            IntPtr duplicateHandle = CreateDuplicateHandle(sourceProcessHandle, (IntPtr)currentHandleInfo.Handle);

            if (duplicateHandle == IntPtr.Zero)
            {
                return;
            }

            String objectType = GetObjectType(duplicateHandle);

            String objectName = String.Empty;

            Thread getObjectNameThread = new Thread(() => objectName = GetObjectName(duplicateHandle));

            getObjectNameThread.IsBackground = true;

            getObjectNameThread.Start();

            if (false == getObjectNameThread.Join(GetObjectNameTimeoutMillis))
            {
                getObjectNameThread.Abort();

                getObjectNameThread.Join(GetObjectNameTimeoutMillis);

                objectName = String.Empty;
            }
            else
            {
                objectName = GetRegularFileName(objectName);
            }

            getObjectNameThread = null;


            if (!String.IsNullOrWhiteSpace(objectType) &&
                !String.IsNullOrWhiteSpace(objectName))
            {
                if (objectName.ToLower().Contains(fileNameToMatch.ToLower()))
                {
                    SystemHandle systemHandle = new SystemHandle();
                    systemHandle.TypeName = objectType;
                    systemHandle.Name = objectName;
                    systemHandle.ObjectTypeNumber = currentHandleInfo.ObjectTypeNumber;
                    systemHandle.ProcessId = currentHandleInfo.ProcessId;
                    systemHandle.ProcessImageName = processImageName;

                    RegisterHandle(systemHandle);
                }
            }

            NativeMethods.CloseHandle(duplicateHandle);
        }

        private void RegisterHandle(SystemHandle systemHandle)
        {
            lock (syncRoot)
            {
                this.systemHandles.Enqueue(systemHandle);
            }
        }

        private String GetObjectName(IntPtr duplicateHandle)
        {
            String objectName = String.Empty;
            IntPtr objectNameBuffer = IntPtr.Zero;

            try
            {
                Int32 objectNameBufferSize = 0x1000;
                objectNameBuffer = Marshal.AllocHGlobal(objectNameBufferSize);
                Int32 actualObjectNameLength;

                UInt32 queryObjectNameResult = NativeMethods.NtQueryObject(
                    duplicateHandle.ToInt32(),
                    NativeMethods.OBJECT_INFORMATION_CLASS.ObjectNameInformation,
                    objectNameBuffer,
                    objectNameBufferSize,
                    out actualObjectNameLength);

                if (queryObjectNameResult != 0 && actualObjectNameLength > 0)
                {
                    Marshal.FreeHGlobal(objectNameBuffer);
                    objectNameBufferSize = actualObjectNameLength;
                    objectNameBuffer = Marshal.AllocHGlobal(objectNameBufferSize);

                    queryObjectNameResult = NativeMethods.NtQueryObject(
                        duplicateHandle.ToInt32(),
                        NativeMethods.OBJECT_INFORMATION_CLASS.ObjectNameInformation,
                        objectNameBuffer,
                        objectNameBufferSize,
                        out actualObjectNameLength);
                }

                // Get the name
                if (queryObjectNameResult == 0)
                {
                    NativeMethods.UNICODE_STRING name = (NativeMethods.UNICODE_STRING)Marshal.PtrToStructure(objectNameBuffer, typeof(NativeMethods.UNICODE_STRING));

                    objectName = name.Buffer;
                }
            }
            catch (ThreadAbortException)
            {
            }
            finally
            {
                if (objectNameBuffer != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(objectNameBuffer);
                }
            }

            return objectName;
        }

        private String GetObjectType(IntPtr duplicateHandle)
        {
            String objectType = String.Empty;

            Int32 objectTypeBufferSize = 0x1000;
            IntPtr objectTypeBuffer = Marshal.AllocHGlobal(objectTypeBufferSize);
            Int32 actualObjectTypeLength;

            UInt32 queryObjectResult = NativeMethods.NtQueryObject(
                duplicateHandle.ToInt32(),
                NativeMethods.OBJECT_INFORMATION_CLASS.ObjectTypeInformation,
                objectTypeBuffer,
                objectTypeBufferSize,
                out actualObjectTypeLength);

            if (queryObjectResult == 0)
            {
                NativeMethods.OBJECT_TYPE_INFORMATION typeInfo = (NativeMethods.OBJECT_TYPE_INFORMATION)Marshal.PtrToStructure(objectTypeBuffer, typeof(NativeMethods.OBJECT_TYPE_INFORMATION));

                objectType = typeInfo.TypeName.Buffer;
            }

            if (objectTypeBuffer != IntPtr.Zero)
            {
                Marshal.FreeHGlobal(objectTypeBuffer);
            }

            return objectType;
        }

        private IntPtr GetProcessHandle(Int32 processId)
        {
            if (this.processIdToHandle.ContainsKey(processId))
            {
                return this.processIdToHandle[processId];
            }

            IntPtr processHandle = NativeMethods.OpenProcess
                (NativeMethods.ProcessAccessFlags.DupHandle | NativeMethods.ProcessAccessFlags.QueryInformation | NativeMethods.ProcessAccessFlags.VMRead, false, processId);

            if (processHandle != IntPtr.Zero)
            {
                this.processIdToHandle.Add(processId, processHandle);
            }
            else
            {
                // throw new Win32Exception(Marshal.GetLastWin32Error());
                //  Console.WriteLine("UNABLE TO OPEN PROCESS {0}", processId);
            }

            return processHandle;
        }

        private String GetProcessImageName(Int32 processId, IntPtr handleToProcess)
        {
            if (this.processIdToImageName.ContainsKey(processId))
            {
                return this.processIdToImageName[processId];
            }

            Int32 bufferSize = 1024;

            String strProcessImageName = String.Empty;

            StringBuilder processImageName = new StringBuilder(bufferSize);

            NativeMethods.QueryFullProcessImageName(handleToProcess, 0, processImageName, ref bufferSize);

            strProcessImageName = processImageName.ToString();

            if (!String.IsNullOrWhiteSpace(strProcessImageName))
            {
                try
                {
                    strProcessImageName = Path.GetFileName(strProcessImageName);
                }
                catch
                {
                }

                this.processIdToImageName.Add(processId, strProcessImageName);
            }

            return strProcessImageName;
        }

        private IntPtr CreateDuplicateHandle(IntPtr sourceProcessHandle, IntPtr handleToDuplicate)
        {
            IntPtr currentProcessHandle = Process.GetCurrentProcess().Handle;

            IntPtr duplicateHandle = IntPtr.Zero;

            NativeMethods.DuplicateHandle(
                sourceProcessHandle,
                handleToDuplicate,
                currentProcessHandle,
                out duplicateHandle,
                0,
                false,
                NativeMethods.DuplicateOptions.DUPLICATE_SAME_ACCESS);

            return duplicateHandle;
        }

        private static String GetRegularFileName(String deviceFileName)
        {
            String actualFileName = String.Empty;

            if (!String.IsNullOrWhiteSpace(deviceFileName))
            {
                foreach (var logicalDrive in Environment.GetLogicalDrives())
                {
                    StringBuilder targetPath = new StringBuilder(4096);

                    if (0 == NativeMethods.QueryDosDevice(logicalDrive.Substring(0, 2), targetPath, 4096))
                    {
                        return targetPath.ToString();
                    }

                    String targetPathStr = targetPath.ToString();

                    if (deviceFileName.StartsWith(targetPathStr))
                    {
                        actualFileName = deviceFileName.Replace(targetPathStr, logicalDrive.Substring(0, 2));

                        break;

                    }
                }

                if (String.IsNullOrWhiteSpace(actualFileName))
                {
                    actualFileName = deviceFileName;
                }
            }

            return actualFileName;
        }

        private void Cleanup()
        {
            foreach (var processHandle in this.processIdToHandle.Values)
            {
                NativeMethods.CloseHandle(processHandle);
            }

            this.processIdToHandle.Clear();
        }
    }

    public class SystemHandle
    {
        public String Name { get; set; }
        public String TypeName { get; set; }
        public byte ObjectTypeNumber { get; set; }
        public Int32 ProcessId { get; set; }
        public String ProcessImageName { get; set; }
    }
  
    public enum HandlesEnumerationScope
    {
        AllSystemHandles,
        ProcessSpecificHandles,
        MatchingFileNameHandles
    }
}
"@

############################################################################################################################

# Global settings for the script.

############################################################################################################################

$ErrorActionPreference = "Stop"

Set-StrictMode -Version 3.0

############################################################################################################################

# Main script.

############################################################################################################################


Add-Type -TypeDefinition $SystemHandlesInfo

Remove-Variable SystemHandlesInfo

if ($PSCmdlet.ParameterSetName -eq 'processId' -and $processId -ne $null) {

       $systemHandlesFinder = New-Object -TypeName SME.SystemHandles -ArgumentList $processId

       $scope = [SME.HandlesEnumerationScope]::ProcessSpecificHandles
}

elseif ($PSCmdlet.ParameterSetName -eq 'handleSubString') {
    
       $SystemHandlesFinder = New-Object -TypeName SME.SystemHandles -ArgumentList $handleSubstring

       $scope = [SME.HandlesEnumerationScope]::MatchingFileNameHandles
}


$SystemHandlesFinder.Enumerate($scope) | out-null

while($SystemHandlesFinder.IsBusy)
{
    $SystemHandlesFinder.ExtractResults() | Write-Output
    $SystemHandlesFinder.WaitForEnumerationToComplete(50) | out-null
}

$SystemHandlesFinder.ExtractResults() | Write-Output
}
## [END] Get-ProcessHandle ##
function Get-ProcessModule {
<#

.SYNOPSIS
Gets services associated with the process.

.DESCRIPTION
Gets services associated with the process.

.ROLE
Readers

#>

param (
    [Parameter(Mandatory=$true)]
    [UInt32]
    $processId
)

$process = Get-Process -PID $processId
$process.Modules | Microsoft.PowerShell.Utility\Select-Object ModuleName, FileVersion, FileName, @{Name="Image"; Expression={$process.Name}}, @{Name="PID"; Expression={$process.id}}


}
## [END] Get-ProcessModule ##
function Get-ProcessService {
<#

.SYNOPSIS
Gets services associated with the process.

.DESCRIPTION
Gets services associated with the process.

.ROLE
Readers

#>

param (
    [Parameter(Mandatory=$true)]
    [Int32]
    $processId
)

Import-Module CimCmdlets -ErrorAction SilentlyContinue

Get-CimInstance -ClassName Win32_service | Where-Object {$_.ProcessId -eq $processId} | Microsoft.PowerShell.Utility\Select-Object Name, processId, Description, Status, StartName



}
## [END] Get-ProcessService ##
function Get-Processes {
<#

.SYNOPSIS
Gets information about the processes running in computer.

.DESCRIPTION
Gets information about the processes running in computer.

.ROLE
Readers

.COMPONENT
ProcessList_Body

#>
param
(
    [Parameter(Mandatory = $true)]
    [boolean]
    $isLocal
)

Import-Module CimCmdlets -ErrorAction SilentlyContinue

$processes = Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTProcess

$powershellProcessList = @{}
$powerShellProcesses = Get-Process -ErrorAction SilentlyContinue

foreach ($process in $powerShellProcesses) {
    $powershellProcessList.Add([int]$process.Id, $process)
}

if ($isLocal) {
    # critical processes taken from task manager code
    # https://microsoft.visualstudio.com/_git/os?path=%2Fbase%2Fdiagnosis%2Fpdui%2Fatm%2FApplications.cpp&version=GBofficial%2Frs_fun_flight&_a=contents&line=44&lineStyle=plain&lineEnd=59&lineStartColumn=1&lineEndColumn=3
    $criticalProcesses = (
        "$($env:windir)\system32\winlogon.exe",
        "$($env:windir)\system32\wininit.exe",
        "$($env:windir)\system32\csrss.exe",
        "$($env:windir)\system32\lsass.exe",
        "$($env:windir)\system32\smss.exe",
        "$($env:windir)\system32\services.exe",
        "$($env:windir)\system32\taskeng.exe",
        "$($env:windir)\system32\taskhost.exe",
        "$($env:windir)\system32\dwm.exe",
        "$($env:windir)\system32\conhost.exe",
        "$($env:windir)\system32\svchost.exe",
        "$($env:windir)\system32\sihost.exe",
        "$($env:ProgramFiles)\Windows Defender\msmpeng.exe",
        "$($env:ProgramFiles)\Windows Defender\nissrv.exe",
        "$($env:ProgramFiles)\Windows Defender\nissrv.exe",
        "$($env:windir)\explorer.exe"
    )

    $sidebarPath = "$($end:ProgramFiles)\Windows Sidebar\sidebar.exe"
    $appFrameHostPath = "$($env:windir)\system32\ApplicationFrameHost.exe"

    $edgeProcesses = (
        "$($env:windir)\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe",
        "$($env:windir)\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdgeCP.exe",
        "$($env:windir)\system32\browser_broker.exe"
    )

    foreach ($process in $processes) {

        if ($powershellProcessList.ContainsKey([int]$process.ProcessId)) {
            $psProcess = $powershellProcessList.Get_Item([int]$process.ProcessId)
            $hasChildWindow = $psProcess -ne $null -and $psProcess.MainWindowHandle -ne 0
            $process | Add-Member -MemberType NoteProperty -Name "HasChildWindow" -Value $hasChildWindow
            if ($psProcess.MainModule -and $psProcess.MainModule.FileVersionInfo) {
                $process | Add-Member -MemberType NoteProperty -Name "FileDescription" -Value $psProcess.MainModule.FileVersionInfo.FileDescription
            }
        }

        if ($edgeProcesses -contains $nativeProcess.executablePath) {
            # special handling for microsoft edge used by task manager
            # group all edge processes into applications
            $edgeLabel = 'Microsoft Edge'
            if ($process.fileDescription) {
                $process.fileDescription = $edgeLabel
            }
            else {
                $process | Add-Member -MemberType NoteProperty -Name "FileDescription" -Value $edgeLabel
            }

            $processType = 'application'
        }
        elseif ($criticalProcesses -contains $nativeProcess.executablePath `
                -or (($nativeProcess.executablePath -eq $null -or $nativeProcess.executablePath -eq '') -and $null -ne ($criticalProcesses | Where-Object {$_ -match $nativeProcess.name})) ) {
            # process is windows if its executable path is a critical process, defined by Task Manager
            # if the process has no executable path recorded, fallback to use the name to match to critical process
            $processType = 'windows'
        }
        elseif (($nativeProcess.hasChildWindow -and $nativeProcess.executablePath -ne $appFrameHostPath) -or $nativeProcess.executablePath -eq $sidebarPath) {
            # sidebar.exe, or has child window (excluding ApplicationFrameHost.exe)
            $processType = 'application'
        }
        else {
            $processType = 'background'
        }

        $process | Add-Member -MemberType NoteProperty -Name "ProcessType" -Value $processType
    }
}

$processes

}
## [END] Get-Processes ##
function New-CimProcessDump {
<#

.SYNOPSIS
Creates a new process dump.

.DESCRIPTION
Creates a new process dump.

.ROLE
Administrators

#>
##SkipCheck=true##

Param(
[System.UInt16]$ProcessId
)

import-module CimCmdlets

$keyInstance = New-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName MSFT_MTProcess -Key @('ProcessId') -Property @{ProcessId=$ProcessId;} -ClientOnly
Invoke-CimMethod $keyInstance -MethodName CreateDump

}
## [END] New-CimProcessDump ##
function New-ProcessDumpDownlevel {
<#

.SYNOPSIS
Creates the mini dump of the process on downlevel computer.

.DESCRIPTION
Creates the mini dump of the process on downlevel computer.

.ROLE
Administrators

#>

param
(
    # The process ID of the process whose mini dump is supposed to be created.
    [int]
    $processId,

    # Path to the process dump file name.
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $fileName
)

$NativeCode = @"

    namespace SME
    {
        using System;
        using System.Diagnostics;
        using System.Runtime.InteropServices;

        public static class ProcessMiniDump
        {
            private enum MINIDUMP_TYPE
            {
                MiniDumpNormal = 0x00000000,
                MiniDumpWithDataSegs = 0x00000001,
                MiniDumpWithFullMemory = 0x00000002,
                MiniDumpWithHandleData = 0x00000004,
                MiniDumpFilterMemory = 0x00000008,
                MiniDumpScanMemory = 0x00000010,
                MiniDumpWithUnloadedModules = 0x00000020,
                MiniDumpWithIndirectlyReferencedMemory = 0x00000040,
                MiniDumpFilterModulePaths = 0x00000080,
                MiniDumpWithProcessThreadData = 0x00000100,
                MiniDumpWithPrivateReadWriteMemory = 0x00000200,
                MiniDumpWithoutOptionalData = 0x00000400,
                MiniDumpWithFullMemoryInfo = 0x00000800,
                MiniDumpWithThreadInfo = 0x00001000,
                MiniDumpWithCodeSegs = 0x00002000
            };

            [DllImport("dbghelp.dll", CallingConvention = CallingConvention.Winapi, SetLastError = true)]
            private extern static bool MiniDumpWriteDump(
                System.IntPtr hProcess,
                int processId,
                Microsoft.Win32.SafeHandles.SafeFileHandle hFile,
                MINIDUMP_TYPE dumpType,
                System.IntPtr exceptionParam,
                System.IntPtr userStreamParam,
                System.IntPtr callbackParam);

            public static void Create(int processId, string fileName)
            {
                if (string.IsNullOrWhiteSpace(fileName))
                {
                    throw new ArgumentNullException(fileName);
                }

                if (processId < 0)
                {
                    throw new ArgumentException("Incorrect value of ProcessId", "processId");
                }

                System.IO.FileStream fileStream = null;

                try
                {
                    fileStream = System.IO.File.OpenWrite(fileName);
                    var proc = Process.GetProcessById(processId);

                    bool success = MiniDumpWriteDump(
                        proc.Handle,
                        proc.Id,
                        fileStream.SafeFileHandle,
                        MINIDUMP_TYPE.MiniDumpWithFullMemory | MINIDUMP_TYPE.MiniDumpWithFullMemoryInfo | MINIDUMP_TYPE.MiniDumpWithHandleData | MINIDUMP_TYPE.MiniDumpWithUnloadedModules | MINIDUMP_TYPE.MiniDumpWithThreadInfo,
                        IntPtr.Zero,
                        IntPtr.Zero,
                        IntPtr.Zero);

                    if (!success)
                    {
                        Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
                    }
                }
                finally
                {
                    if (fileStream != null)
                    {
                        fileStream.Close();
                    }
                }
            }
        }
}

"@

############################################################################################################################

# Global settings for the script.

############################################################################################################################

$ErrorActionPreference = "Stop"

Set-StrictMode -Version 3.0

############################################################################################################################

# Main script.

############################################################################################################################

Add-Type -TypeDefinition $NativeCode
Remove-Variable NativeCode

$fileName = "$($env:temp)\$($fileName)"

try {
    # Create the mini dump using native call.
    try {
        [SME.ProcessMiniDump]::Create($processId, $fileName)
        $result = New-Object PSObject
        $result | Add-Member -MemberType NoteProperty -Name 'DumpFilePath' -Value $fileName
        $result
    }
    catch {
        if ($_.FullyQualifiedErrorId -eq "ArgumentException") {
            throw "Unable to create the mini dump of the process. Please make sure that the processId is correct and the user has required permissions to create the mini dump of the process."
        }
        elseif ($_.FullyQualifiedErrorId -eq "UnauthorizedAccessException") {
            throw "Access is denied. User does not relevant permissions to create the mini dump of process with ID: {0}" -f $processId
        }
        else {
            throw
        }
    }
}
finally {
    if (Test-Path $fileName) {
        if ((Get-Item $fileName).length -eq 0) {
            # Delete the zero byte file.
            Remove-Item -Path $fileName -Force -ErrorAction Stop
        }
    }
}

}
## [END] New-ProcessDumpDownlevel ##
function Start-CimProcess {
<#

.SYNOPSIS
Starts new process.

.DESCRIPTION
Starts new process.

.ROLE
Administrators

#>
##SkipCheck=true##

Param(
[string]$CommandLine
)

import-module CimCmdlets

Invoke-CimMethod -Namespace root/Microsoft/Windows/ManagementTools -ClassName MSFT_MTProcess -MethodName CreateProcess -Arguments @{CommandLine=$CommandLine;}

}
## [END] Start-CimProcess ##
function Start-ProcessDownlevel {
<#

.SYNOPSIS
Start a new process on downlevel computer.

.DESCRIPTION
Start a new process on downlevel computer.

.ROLE
Administrators

#>

param
(
	[Parameter(Mandatory = $true)]
	[string]
	$commandLine
)

Set-StrictMode -Version 5.0

Start-Process $commandLine

}
## [END] Start-ProcessDownlevel ##
function Stop-CimProcess {
<#

.SYNOPSIS
Stop a process.

.DESCRIPTION
Stop a process.

.ROLE
Administrators

#>
##SkipCheck=true##

Param(
[System.UInt16]$ProcessId
)

import-module CimCmdlets

$instance = New-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName MSFT_MTProcess -Key @('ProcessId') -Property @{ProcessId=$ProcessId;} -ClientOnly
Remove-CimInstance $instance

}
## [END] Stop-CimProcess ##
function Stop-Processes {
<#

.SYNOPSIS
Stop the process on a computer.

.DESCRIPTION
Stop the process on a computer.

.ROLE
Administrators

#>

param
(
	[Parameter(Mandatory = $true)]
	[int[]]
	$processIds
)

Set-StrictMode -Version 5.0

Stop-Process $processIds -Force

}
## [END] Stop-Processes ##
function Get-CimWin32LogicalDisk {
<#

.SYNOPSIS
Gets Win32_LogicalDisk object.

.DESCRIPTION
Gets Win32_LogicalDisk object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_LogicalDisk

}
## [END] Get-CimWin32LogicalDisk ##
function Get-CimWin32NetworkAdapter {
<#

.SYNOPSIS
Gets Win32_NetworkAdapter object.

.DESCRIPTION
Gets Win32_NetworkAdapter object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_NetworkAdapter

}
## [END] Get-CimWin32NetworkAdapter ##
function Get-CimWin32PhysicalMemory {
<#

.SYNOPSIS
Gets Win32_PhysicalMemory object.

.DESCRIPTION
Gets Win32_PhysicalMemory object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PhysicalMemory

}
## [END] Get-CimWin32PhysicalMemory ##
function Get-CimWin32Processor {
<#

.SYNOPSIS
Gets Win32_Processor object.

.DESCRIPTION
Gets Win32_Processor object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_Processor

}
## [END] Get-CimWin32Processor ##
function Get-ClusterInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a cluster.

.DESCRIPTION
Retrieves the inventory data for a cluster.

.ROLE
Readers

#>

import-module CimCmdlets -ErrorAction SilentlyContinue

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the name of this computer.

.DESCRIPTION
Get the best available name for this computer.  The FQDN is preferred, but when not avaialble
the NetBIOS name will be used instead.

#>

function getComputerName() {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object Name, DNSHostName

    if ($computerSystem) {
        $computerName = $computerSystem.DNSHostName

        if ($null -eq $computerName) {
            $computerName = $computerSystem.Name
        }

        return $computerName
    }

    return $null
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
Get the MSCluster Cluster CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster CIM instance from this server.

#>
function getClusterCimInstance() {
    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespace) {
        return Get-CimInstance -Namespace root/mscluster MSCluster_Cluster -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object fqdn, S2DEnabled
    }

    return $null
}


<#

.SYNOPSIS
Determines if the current cluster supports Failover Clusters Time Series Database.

.DESCRIPTION
Use the existance of the path value of cmdlet Get-StorageHealthSetting to determine if TSDB 
is supported or not.

#>
function getClusterPerformanceHistoryPath() {
    return $null -ne (Get-StorageSubSystem clus* | Get-StorageHealthSetting -Name "System.PerformanceHistory.Path")
}

<#

.SYNOPSIS
Get some basic information about the cluster from the cluster.

.DESCRIPTION
Get the needed cluster properties from the cluster.

#>
function getClusterInfo() {
    $returnValues = @{}

    $returnValues.Fqdn = $null
    $returnValues.isS2DEnabled = $false
    $returnValues.isTsdbEnabled = $false

    $cluster = getClusterCimInstance
    if ($cluster) {
        $returnValues.Fqdn = $cluster.fqdn
        $isS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -eq 1)
        $returnValues.isS2DEnabled = $isS2dEnabled

        if ($isS2DEnabled) {
            $returnValues.isTsdbEnabled = getClusterPerformanceHistoryPath
        } else {
            $returnValues.isTsdbEnabled = $false
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Are the cluster PowerShell Health cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell Health cmdlets installed on this server?

s#>
function getisClusterHealthCmdletAvailable() {
    $cmdlet = Get-Command -Name "Get-HealthFault" -ErrorAction SilentlyContinue

    return !!$cmdlet
}
<#

.SYNOPSIS
Are the Britannica (sddc management resources) available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) available on the cluster?

#>
function getIsBritannicaEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_Cluster -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual machine available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual machine available on the cluster?

#>
function getIsBritannicaVirtualMachineEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualMachine -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual switch available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual switch available on the cluster?

#>
function getIsBritannicaVirtualSwitchEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualSwitch -ErrorAction SilentlyContinue)
}

###########################################################################
# main()
###########################################################################

$clusterInfo = getClusterInfo

$result = New-Object PSObject

$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $clusterInfo.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2DEnabled' -Value $clusterInfo.isS2DEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsTsdbEnabled' -Value $clusterInfo.isTsdbEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterHealthCmdletAvailable' -Value (getIsClusterHealthCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaEnabled' -Value (getIsBritannicaEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualMachineEnabled' -Value (getIsBritannicaVirtualMachineEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualSwitchEnabled' -Value (getIsBritannicaVirtualSwitchEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterCmdletAvailable' -Value (getIsClusterCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'CurrentClusterNode' -Value (getComputerName)

$result

}
## [END] Get-ClusterInventory ##
function Get-ClusterNodes {
<#

.SYNOPSIS
Retrieves the inventory data for cluster nodes in a particular cluster.

.DESCRIPTION
Retrieves the inventory data for cluster nodes in a particular cluster.

.ROLE
Readers

#>

import-module CimCmdlets

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed?

.DESCRIPTION
Use the Get-Command cmdlet to quickly test if the cluster PowerShell cmdlets
are installed on this server.

#>

function getClusterPowerShellSupport() {
    $cmdletInfo = Get-Command 'Get-ClusterNode' -ErrorAction SilentlyContinue

    return $cmdletInfo -and $cmdletInfo.Name -eq "Get-ClusterNode"
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster CIM provider.

.DESCRIPTION
When the cluster PowerShell cmdlets are not available fallback to using
the cluster CIM provider to get the needed information.

#>

function getClusterNodeCimInstances() {
    # Change the WMI property NodeDrainStatus to DrainStatus to match the PS cmdlet output.
    return Get-CimInstance -Namespace root/mscluster MSCluster_Node -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object @{Name="DrainStatus"; Expression={$_.NodeDrainStatus}}, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster PowerShell cmdlets.

.DESCRIPTION
When the cluster PowerShell cmdlets are available use this preferred function.

#>

function getClusterNodePsInstances() {
    return Get-ClusterNode -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object DrainStatus, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Use DNS services to get the FQDN of the cluster NetBIOS name.

.DESCRIPTION
Use DNS services to get the FQDN of the cluster NetBIOS name.

.Notes
It is encouraged that the caller add their approprate -ErrorAction when
calling this function.

#>

function getClusterNodeFqdn([string]$clusterNodeName) {
    return ([System.Net.Dns]::GetHostEntry($clusterNodeName)).HostName
}

<#

.SYNOPSIS
Writes message to event log as warning.

.DESCRIPTION
Writes message to event log as warning.

#>

function writeToEventLog([string]$message) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
        -Message $message  -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the cluster nodes.

.DESCRIPTION
When the cluster PowerShell cmdlets are available get the information about the cluster nodes
using PowerShell.  When the cmdlets are not available use the Cluster CIM provider.

#>

function getClusterNodes() {
    $isClusterCmdletAvailable = getClusterPowerShellSupport

    if ($isClusterCmdletAvailable) {
        $clusterNodes = getClusterNodePsInstances
    } else {
        $clusterNodes = getClusterNodeCimInstances
    }

    $clusterNodeMap = @{}

    foreach ($clusterNode in $clusterNodes) {
        $clusterNodeName = $clusterNode.Name.ToLower()
        try 
        {
            $clusterNodeFqdn = getClusterNodeFqdn $clusterNodeName -ErrorAction SilentlyContinue
        }
        catch 
        {
            $clusterNodeFqdn = $clusterNodeName
            writeToEventLog "[$ScriptName]: The fqdn for node '$clusterNodeName' could not be obtained. Defaulting to machine name '$clusterNodeName'"
        }

        $clusterNodeResult = New-Object PSObject

        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FullyQualifiedDomainName' -Value $clusterNodeFqdn
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'Name' -Value $clusterNodeName
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DynamicWeight' -Value $clusterNode.DynamicWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'NodeWeight' -Value $clusterNode.NodeWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FaultDomain' -Value $clusterNode.FaultDomain
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'State' -Value $clusterNode.State
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DrainStatus' -Value $clusterNode.DrainStatus

        $clusterNodeMap.Add($clusterNodeName, $clusterNodeResult)
    }

    return $clusterNodeMap
}

###########################################################################
# main()
###########################################################################

getClusterNodes

}
## [END] Get-ClusterNodes ##
function Get-ServerInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a server.

.DESCRIPTION
Retrieves the inventory data for a server.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

Import-Module CimCmdlets

<#

.SYNOPSIS
Converts an arbitrary version string into just 'Major.Minor'

.DESCRIPTION
To make OS version comparisons we only want to compare the major and 
minor version.  Build number and/os CSD are not interesting.

#>

function convertOsVersion([string]$osVersion) {
    [Ref]$parsedVersion = $null
    if (![Version]::TryParse($osVersion, $parsedVersion)) {
        return $null
    }

    $version = [Version]$parsedVersion.Value
    return New-Object Version -ArgumentList $version.Major, $version.Minor
}

<#

.SYNOPSIS
Determines if CredSSP is enabled for the current server or client.

.DESCRIPTION
Check the registry value for the CredSSP enabled state.

#>

function isCredSSPEnabled() {
    Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP"
    Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP"

    $credSSPServerEnabled = $false;
    $credSSPClientEnabled = $false;

    $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
    if ($credSSPServerService) {
        $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
    }

    $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
    if ($credSSPClientService) {
        $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
    }

    return ($credSSPServerEnabled -or $credSSPClientEnabled)
}

<#

.SYNOPSIS
Determines if the Hyper-V role is installed for the current server or client.

.DESCRIPTION
The Hyper-V role is installed when the VMMS service is available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>

function isHyperVRoleInstalled() {
    $vmmsService = Get-Service -Name "VMMS" -ErrorAction SilentlyContinue

    return $vmmsService -and $vmmsService.Name -eq "VMMS"
}

<#

.SYNOPSIS
Determines if the Hyper-V PowerShell support module is installed for the current server or client.

.DESCRIPTION
The Hyper-V PowerShell support module is installed when the modules cmdlets are available.  This is much
faster then checking Get-WindowsFeature and works on Windows Client SKUs.

#>
function isHyperVPowerShellSupportInstalled() {
    # quicker way to find the module existence. it doesn't load the module.
    return !!(Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Determines if Windows Management Framework (WMF) 5.0, or higher, is installed for the current server or client.

.DESCRIPTION
Windows Admin Center requires WMF 5 so check the registey for WMF version on Windows versions that are less than
Windows Server 2016.

#>
function isWMF5Installed([string] $operatingSystemVersion) {
    Set-Variable Server2016 -Option Constant -Value (New-Object Version '10.0')   # And Windows 10 client SKUs
    Set-Variable Server2012 -Option Constant -Value (New-Object Version '6.2')

    $version = convertOsVersion $operatingSystemVersion
    if (-not $version) {
        # Since the OS version string is not properly formatted we cannot know the true installed state.
        return $false
    }

    if ($version -ge $Server2016) {
        # It's okay to assume that 2016 and up comes with WMF 5 or higher installed
        return $true
    }
    else {
        if ($version -ge $Server2012) {
            # Windows 2012/2012R2 are supported as long as WMF 5 or higher is installed
            $registryKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'
            $registryKeyValue = Get-ItemProperty -Path $registryKey -Name PowerShellVersion -ErrorAction SilentlyContinue

            if ($registryKeyValue -and ($registryKeyValue.PowerShellVersion.Length -ne 0)) {
                $installedWmfVersion = [Version]$registryKeyValue.PowerShellVersion

                if ($installedWmfVersion -ge [Version]'5.0') {
                    return $true
                }
            }
        }
    }

    return $false
}

<#

.SYNOPSIS
Determines if the current usser is a system administrator of the current server or client.

.DESCRIPTION
Determines if the current usser is a system administrator of the current server or client.

#>
function isUserAnAdministrator() {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

<#

.SYNOPSIS
Get some basic information about the Failover Cluster that is running on this server.

.DESCRIPTION
Create a basic inventory of the Failover Cluster that may be running in this server.

#>
function getClusterInformation() {
    $returnValues = @{}

    $returnValues.IsS2dEnabled = $false
    $returnValues.IsCluster = $false
    $returnValues.ClusterFqdn = $null

    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue
    if ($namespace) {
        $cluster = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            $returnValues.IsCluster = $true
            $returnValues.ClusterFqdn = $cluster.Fqdn
            $returnValues.IsS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -gt 0)
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.

#>
function getComputerFqdnAndAddress($computerName) {
    $hostEntry = [System.Net.Dns]::GetHostEntry($computerName)
    $addressList = @()
    foreach ($item in $hostEntry.AddressList) {
        $address = New-Object PSObject
        $address | Add-Member -MemberType NoteProperty -Name 'IpAddress' -Value $item.ToString()
        $address | Add-Member -MemberType NoteProperty -Name 'AddressFamily' -Value $item.AddressFamily.ToString()
        $addressList += $address
    }

    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $hostEntry.HostName
    $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $addressList
    return $result
}

<#

.SYNOPSIS
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

.DESCRIPTION
Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.

#>
function getHostFqdnAndAddress($computerSystem) {
    $computerName = $computerSystem.DNSHostName
    if (!$computerName) {
        $computerName = $computerSystem.Name
    }

    return getComputerFqdnAndAddress $computerName
}

<#

.SYNOPSIS
Are the needed management CIM interfaces available on the current server or client.

.DESCRIPTION
Check for the presence of the required server management CIM interfaces.

#>
function getManagementToolsSupportInformation() {
    $returnValues = @{}

    $returnValues.ManagementToolsAvailable = $false
    $returnValues.ServerManagerAvailable = $false

    $namespaces = Get-CimInstance -Namespace root/microsoft/windows -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespaces) {
        $returnValues.ManagementToolsAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ManagementTools" })
        $returnValues.ServerManagerAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ServerManager" })
    }

    return $returnValues
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>
function isRemoteAppEnabled() {
    Set-Variable key -Option Constant -Value "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\TSAppAllowList"

    $registryKeyValue = Get-ItemProperty -Path $key -Name fDisabledAllowList -ErrorAction SilentlyContinue

    if (-not $registryKeyValue) {
        return $false
    }
    return $registryKeyValue.fDisabledAllowList -eq 1
}

<#

.SYNOPSIS
Check the remote app enabled or not.

.DESCRIPTION
Check the remote app enabled or not.

#>

<#
c
.SYNOPSIS
Get the Win32_OperatingSystem information

.DESCRIPTION
Get the Win32_OperatingSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getOperatingSystemInfo() {
    return Get-CimInstance Win32_OperatingSystem | Microsoft.PowerShell.Utility\Select-Object csName, Caption, OperatingSystemSKU, Version, ProductType
}

<#

.SYNOPSIS
Get the Win32_ComputerSystem information

.DESCRIPTION
Get the Win32_ComputerSystem instance and filter the results to just the required properties.
This filtering will make the response payload much smaller.

#>
function getComputerSystemInfo() {
    return Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object TotalPhysicalMemory, DomainRole, Manufacturer, Model, NumberOfLogicalProcessors, Domain, Workgroup, DNSHostName, Name, PartOfDomain
}

###########################################################################
# main()
###########################################################################

$operatingSystem = getOperatingSystemInfo
$computerSystem = getComputerSystemInfo
$isAdministrator = isUserAnAdministrator
$fqdnAndAddress = getHostFqdnAndAddress $computerSystem
$hostname = hostname
$netbios = $env:ComputerName
$managementToolsInformation = getManagementToolsSupportInformation
$isWmfInstalled = isWMF5Installed $operatingSystem.Version
$clusterInformation = getClusterInformation -ErrorAction SilentlyContinue
$isHyperVPowershellInstalled = isHyperVPowerShellSupportInstalled
$isHyperVRoleInstalled = isHyperVRoleInstalled
$isCredSSPEnabled = isCredSSPEnabled
$isRemoteAppEnabled = isRemoteAppEnabled

$result = New-Object PSObject
$result | Add-Member -MemberType NoteProperty -Name 'IsAdministrator' -Value $isAdministrator
$result | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $operatingSystem
$result | Add-Member -MemberType NoteProperty -Name 'ComputerSystem' -Value $computerSystem
$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $fqdnAndAddress.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $fqdnAndAddress.AddressList
$result | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $hostname
$result | Add-Member -MemberType NoteProperty -Name 'NetBios' -Value $netbios
$result | Add-Member -MemberType NoteProperty -Name 'IsManagementToolsAvailable' -Value $managementToolsInformation.ManagementToolsAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsServerManagerAvailable' -Value $managementToolsInformation.ServerManagerAvailable
$result | Add-Member -MemberType NoteProperty -Name 'IsWmfInstalled' -Value $isWmfInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCluster' -Value $clusterInformation.IsCluster
$result | Add-Member -MemberType NoteProperty -Name 'ClusterFqdn' -Value $clusterInformation.ClusterFqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2dEnabled' -Value $clusterInformation.IsS2dEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVRoleInstalled' -Value $isHyperVRoleInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsHyperVPowershellInstalled' -Value $isHyperVPowershellInstalled
$result | Add-Member -MemberType NoteProperty -Name 'IsCredSSPEnabled' -Value $isCredSSPEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsRemoteAppEnabled' -Value $isRemoteAppEnabled

$result

}
## [END] Get-ServerInventory ##
function Install-MMAgent {
<#

.SYNOPSIS
Download and install Microsoft Monitoring Agent for Windows.

.DESCRIPTION
Download and install Microsoft Monitoring Agent for Windows.

.PARAMETER workspaceId
The log analytics workspace id a target node has to connect to.

.PARAMETER workspacePrimaryKey
The primary key of log analytics workspace.

.PARAMETER taskName
The task name.

.ROLE
Readers

#>

param(
    [Parameter(Mandatory = $true)]
    [String]
    $workspaceId,
    [Parameter(Mandatory = $true)]
    [String]
    $workspacePrimaryKey,
    [Parameter(Mandatory = $true)]
    [String]
    $taskName
)

$Script = @'
$mmaExe = Join-Path -Path $env:temp -ChildPath 'MMASetup-AMD64.exe'
if (Test-Path $mmaExe) {
    Remove-Item $mmaExe
}

Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkId=828603 -OutFile $mmaExe

$extractFolder = Join-Path -Path $env:temp -ChildPath 'SmeMMAInstaller'
if (Test-Path $extractFolder) {
    Remove-Item $extractFolder -Force -Recurse
}

&$mmaExe /c /t:$extractFolder
$setupExe = Join-Path -Path $extractFolder -ChildPath 'setup.exe'
for ($i=1; $i -le 10; $i++) {
    if(-Not(Test-Path $setupExe)) {
        sleep -s 6
    }
}

&$setupExe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$workspaceId OPINSIGHTS_WORKSPACE_KEY=$workspacePrimaryKey AcceptEndUserLicenseAgreement=1
'@

$Script = '$workspaceId = ' + "'$workspaceId';" + $Script
$Script = '$workspacePrimaryKey =' + "'$workspacePrimaryKey';" + $Script

$ScriptFile = Join-Path -Path $env:LocalAppData -ChildPath "$taskName.ps1"
$ResultFile = Join-Path -Path $env:temp -ChildPath "$taskName.log"
if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script | Out-File $ScriptFile
if (-Not(Test-Path $ScriptFile)) {
    $message = "Failed to create file:" + $ScriptFile
    Write-Error $message
    return #If failed to create script file, no need continue just return here
}

#Create a scheduled task
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -c $ScriptFile >> $ResultFile 2>&1"
if(!$Role)
{
  Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."
}

$Scheduler = New-Object -ComObject Schedule.Service

#Try to connect to schedule service 3 time since it may fail the first time
for ($i=1; $i -le 3; $i++)
{
  Try
  {
    $Scheduler.Connect()
    Break
  }
  Catch
  {
    if($i -ge 3)
    {
      Write-EventLog -LogName Application -Source "SME Register $taskName" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
      Write-Error "Can't connect to Schedule service" -ErrorAction Stop
    }
    else
    {
      Start-Sleep -s 1
    }
  }
}

$RootFolder = $Scheduler.GetFolder("\")
#Delete existing task
if($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Write-Debug("Deleting existing task" + $TaskName)
  $RootFolder.DeleteTask($TaskName,0)
}

$Task = $Scheduler.NewTask(0)
$RegistrationInfo = $Task.RegistrationInfo
$RegistrationInfo.Description = $TaskName
$RegistrationInfo.Author = $User.Name

$Triggers = $Task.Triggers
$Trigger = $Triggers.Create(7) #TASK_TRIGGER_REGISTRATION: Starts the task when the task is registered.
$Trigger.Enabled = $true

$Settings = $Task.Settings
$Settings.Enabled = $True
$Settings.StartWhenAvailable = $True
$Settings.Hidden = $False
$Settings.ExecutionTimeLimit  = "PT20M" # 20 minutes

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#Start the task to run in Local System account. 6: TASK_CREATE_OR_UPDATE
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Start-Sleep -s 1
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile

if (Test-Path $ResultFile)
{
    Get-Content -Path $ResultFile | Out-String -Stream
    Remove-Item $ResultFile
}

}
## [END] Install-MMAgent ##

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgBBNHiH5P7F+3pWctJXSu+MN
# a0KgghhuMIIE3jCCA8agAwIBAgITMwAAAPfdvzTg5NWCYAAAAAAA9zANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDAy
# WhcNMTkxMTIzMjAyMDAyWjCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjdEMkUtMzc4Mi1CMEY3MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA3nEYJOthhViLNfJ3TBvlYEfBf7ap9sFWO/VXhvxg
# oNT6yJT2ZJjY/WbvzyYr4eaV6xqRUr0WM+sYmOaHioAKaoVRm3rTboJa+ggffCou
# AAX2MwVp41p3ojfe2HTnAUSiw+G28J6eyggABXmPSbAl0Y7kjibEEnVjNIK5ycYz
# 4B0CefTmxi7LKfTL4JYpyP9IXH1BjUDZ4VszdvN+57LDPc2Wsf5kGGTVizX7znqv
# 99TSoldE0kilSZyfwotZcFRfObsImAYH5r6eMMuC2kJR5kYUCWkt7W5gSZ/wqAL3
# tEEbkkRR561DjwjfgAY/8CILNRr5NoPCyj2fgr2wlxZeGwIDAQABo4IBCTCCAQUw
# HQYDVR0OBBYEFFkoL/rgdU0f1ZHJFNOCZplml0/bMB8GA1UdIwQYMBaAFCM0+NlS
# RnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdFRpbWVTdGFtcFBD
# QS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcnQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggEBAGLhSXaU0PCt
# JC8w07NjC/pFMxBbsAr9v0Vx5PFm+R9sglray9H7RCDOc+snob0MdTpqPwHavJqW
# PrnI/zwWX7C5gb4GtarS08hcTDPEeqCxCQWCdmI1WB5ReZRjcEu4/3Yt0kldEdor
# v94tu4VNPdHEK54CJ+Zaz7KPEBJNDKW5gUh21Po1nx4f1oIATChhmTGoRJdGi5pO
# VM+P+LTpAEAD1RwWTNHB1q7ofM3Mwb7q0v81TsDOtXqtu6a7LtyU6fMefeDsKKMH
# gmZaw1tay+wDyeMslBUhK6D52ZtL57be6yBRjD76LCPVGLDwsaBwbHrvi4NIpjoC
# Bu+giiy3iEUwggX/MIID56ADAgECAhMzAAABA14lHJkfox64AAAAAAEDMA0GCSqG
# SIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwHhcNMTgw
# NzEyMjAwODQ4WhcNMTkwNzI2MjAwODQ4WjB0MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRlHY25oarNv5p+UZ8i4hQ
# y5Bwf7BVqSQdfjnnBZ8PrHuXss5zCvvUmyRcFrU53Rt+M2wR/Dsm85iqXVNrqsPs
# E7jS789Xf8xly69NLjKxVitONAeJ/mkhvT5E+94SnYW/fHaGfXKxdpth5opkTEbO
# ttU6jHeTd2chnLZaBl5HhvU80QnKDT3NsumhUHjRhIjiATwi/K+WCMxdmcDt66Va
# mJL1yEBOanOv3uN0etNfRpe84mcod5mswQ4xFo8ADwH+S15UD8rEZT8K46NG2/Ys
# AzoZvmgFFpzmfzS/p4eNZTkmyWPU78XdvSX+/Sj0NIZ5rCrVXzCRO+QUauuxygQj
# AgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEEAYI3TAgBBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUR77Ay+GmP/1l1jjyA123r3f3QP8wUAYDVR0RBEkwR6RFMEMxKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY1MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAn/XJUw0/DSbsokTYDdGfY5YGSz8e
# XMUzo6TDbK8fwAG662XsnjMQD6esW9S9kGEX5zHnwya0rPUn00iThoj+EjWRZCLR
# ay07qCwVlCnSN5bmNf8MzsgGFhaeJLHiOfluDnjYDBu2KWAndjQkm925l3XLATut
# ghIWIoCJFYS7mFAgsBcmhkmvzn1FFUM0ls+BXBgs1JPyZ6vic8g9o838Mh5gHOmw
# GzD7LLsHLpaEk0UoVFzNlv2g24HYtjDKQ7HzSMCyRhxdXnYqWJ/U7vL0+khMtWGL
# sIxB6aq4nZD0/2pCD7k+6Q7slPyNgLt44yOneFuybR/5WcF9ttE5yXnggxxgCto9
# sNHtNr9FB+kbNm7lPTsFA6fUpyUSj+Z2oxOzRVpDMYLa2ISuubAfdfX2HX1RETcn
# 6LU1hHH3V6qu+olxyZjSnlpkdr6Mw30VapHxFPTy2TUxuNty+rR1yIibar+YRcdm
# stf/zpKQdeTr5obSyBvbJ8BblW9Jb1hdaSreU0v46Mp79mwV+QMZDxGFqk+av6pX
# 3WDG9XEg9FGomsrp0es0Rz11+iLsVT9qGTlrEOlaP470I3gwsvKmOMs1jaqYWSRA
# uDpnpAdfoP7YO0kT+wzh7Qttg1DO8H8+4NkI6IwhSkHC3uuOW+4Dwx1ubuZUNWZn
# cnwa6lL2IsRyP64wggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABA14lHJkfox64AAAAAAEDMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDySnmeLUWjxJuTntFZW0TVw
# oSBmMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAPVKac3tU
# +aSMdASBsC2ip7Rrq+DZPc+ddWUVQ0FnQ4j7cqvYmv4ctTd0kZw7VIJOTy1p0guV
# xFB/9x4m9eL1ddvIaF7xrK3pGyaeDHMQEQT9xKhdEhqndNOGPZht6yXUfiLTO5H0
# lZsxJ4Zvd44kbplelCKGfV4GenMC9o9JcbfdffOMZHYiHW/YSCJWQjSA/Ez/EEHe
# GR9rcPcCQybH1PrD3dp8Uo/M6k9Fgkk7zskARgPfZcpz39q9DqRxjjPeUfHGLnFQ
# tQ5hIwYmRVR1mU+oOMaveQZntN9YDuXWaWE78i/A8G+FvqMHgpnGpgH+/hBsJ1PK
# Bnc+uy2Oc931FaGCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAD33b804OTVgmAAAAAAAPcwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDQwMjE5MzMzM1owIwYJKoZIhvcNAQkEMRYEFDwCzOQ6H0nBTnIgp0MiszuN
# ItfwMA0GCSqGSIb3DQEBBQUABIIBAFFxO64X2aN0xsG8kvis1r5ZBBUGvpnAneTm
# 1dfgnYS7H4mLVm2xDArsWwUMR0lXdIBFqoMYC85NTDUFhNzPUfSWUEYn7KLR6zWg
# 1vRSXKwG8Q2ESs44IL4EMHPWkN4yJghypwKyqgypGg2KnSQQ0yc/ZSsIuDdx2gzI
# p/pgVXU9Cw1dnwZ3dadSdPCCuw/f5uF+yjJj1H9/gBjjX/MpGzT9r0Z/N1nMpsol
# G7tcGOIWJywT4cxyREEV6xp+aDrMuBiRFzpTNW/PMKK23iEACAl3K68CjBGuNJ35
# diZUUo1VqGZ/5CNyRzRLeimqwZVaS2NVCwCDoHfG5KPeV6ERUW4=
# SIG # End signature block
