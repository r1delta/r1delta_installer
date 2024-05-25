local ffi = require("ffi")

ffi.cdef([[
    typedef void* HKEY;
    typedef unsigned short WORD;
    typedef unsigned long DWORD;
    typedef DWORD* LPDWORD;
    typedef char* LPSTR;
    typedef const char* LPCSTR;
    typedef char CHAR;
    typedef void* PVOID;
    typedef PVOID HANDLE;
    typedef long LSTATUS;
    typedef int BOOL;
    typedef PVOID HWND;

    typedef struct tagOFNA {
        DWORD        lStructSize;
        HWND         hwndOwner;
        PVOID        hInstance;
        LPCSTR       lpstrFilter;
        LPSTR        lpstrCustomFilter;
        DWORD        nMaxCustFilter;
        DWORD        nFilterIndex;
        LPSTR        lpstrFile;
        DWORD        nMaxFile;
        LPSTR        lpstrFileTitle;
        DWORD        nMaxFileTitle;
        LPCSTR       lpstrInitialDir;
        LPCSTR       lpstrTitle;
        DWORD        Flags;
        WORD         nFileOffset;
        WORD         nFileExtension;
        LPCSTR       lpstrDefExt;
        PVOID        lCustData;
        PVOID        lpfnHook;
        LPCSTR       lpTemplateName;
        void *        pvReserved;
        DWORD        dwReserved;
        DWORD        FlagsEx;
    } OPENFILENAMEA, *LPOPENFILENAMEA;
    BOOL GetOpenFileNameA(LPOPENFILENAMEA unnamedParam1);
    DWORD CommDlgExtendedError();

    typedef struct tagPROCESSENTRY32 {
        DWORD       dwSize;
        DWORD       cntUsage;
        DWORD       th32ProcessID;
        LPDWORD     th32DefaultHeapID;
        DWORD       th32ModuleID;
        DWORD       cntThreads;
        DWORD       th32ParentProcessID;
        DWORD       pcPriClassBase;
        DWORD       dwFlags;
        CHAR        szExeFile[260];
    } PROCESSENTRY32, *LPPROCESSENTRY32;
    HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
    BOOL Process32First(HANDLE hSnapshot, LPPROCESSENTRY32 lppe);
    BOOL Process32Next(HANDLE hSnapshot, LPPROCESSENTRY32 lppe);
    BOOL CloseHandle(HANDLE hObject);
    

    LSTATUS RegGetValueA(HKEY hkey, LPCSTR lpSubKey, LPCSTR lpValue, DWORD dwFlags, LPDWORD pdwType, PVOID pvData, LPDWORD pcbData);
    BOOL CreateDirectoryA(LPCSTR lpPathName, PVOID lpSecurityAttributes);
    DWORD GetLastError();
    BOOL DeleteFileA(LPCSTR lpFileName);
    BOOL RemoveDirectoryA(LPCSTR lpFileName);
]])

comdlg32 = ffi.load("comdlg32.dll")

-- [[ Errors ]] --
CDERR_DIALOGFAILURE     = 0xFFFF    -- The dialog box could not be created. The common dialog box function's call to the DialogBox function failed. For example, this error occurs if the common dialog box call specifies an invalid window handle.
CDERR_FINDRESFAILURE    = 0x0006    -- The common dialog box function failed to find a specified resource.
CDERR_INITIALIZATION    = 0x0002    -- The common dialog box function failed during initialization. This error often occurs when sufficient memory is not available.
CDERR_LOADRESFAILURE    = 0x0007    -- The common dialog box function failed to load a specified resource.
CDERR_LOADSTRFAILURE    = 0x0005    -- The common dialog box function failed to load a specified string.
CDERR_LOCKRESFAILURE    = 0x0008    -- The common dialog box function failed to lock a specified resource.
CDERR_MEMALLOCFAILURE   = 0x0009    -- The common dialog box function was unable to allocate memory for internal structures.
CDERR_MEMLOCKFAILURE    = 0x000A    -- The common dialog box function was unable to lock the memory associated with a handle.
CDERR_NOHINSTANCE       = 0x0004    -- The ENABLETEMPLATE flag was set in the Flags member of the initialization structure for the corresponding common dialog box, but you failed to provide a corresponding instance handle.
CDERR_NOHOOK            = 0x000B    -- The ENABLEHOOK flag was set in the Flags member of the initialization structure for the corresponding common dialog box, but you failed to provide a pointer to a corresponding hook procedure.
CDERR_NOTEMPLATE        = 0x0003    -- The ENABLETEMPLATE flag was set in the Flags member of the initialization structure for the corresponding common dialog box, but you failed to provide a corresponding template.
CDERR_REGISTERMSGFAIL   = 0x000C    -- The RegisterWindowMessage function returned an error code when it was called by the common dialog box function.
CDERR_STRUCTSIZE        = 0x0001    -- The lStructSize member of the initialization structure for the corresponding common dialog box is invalid. 
FNERR_BUFFERTOOSMALL    = 0x3003    -- The buffer pointed to by the lpstrFile member of the OPENFILENAME structure is too small for the file name specified by the user. The first two bytes of the lpstrFile buffer contain an integer value specifying the size required to receive the full name, in characters.
FNERR_INVALIDFILENAME   = 0x3002    -- A file name is invalid.
FNERR_SUBCLASSFAILURE   = 0x3001    -- An attempt to subclass a list box failed because sufficient memory was not available. 

TH32CS_INHERIT      = 0x80000000 -- Indicates that the snapshot handle is to be inheritable.
TH32CS_SNAPHEAPLIST = 0x00000001 -- Includes all heaps of the process specified in th32ProcessID in the snapshot. To enumerate the heaps, see Heap32ListFirst.
TH32CS_SNAPMODULE   = 0x00000008 -- Includes all modules of the process specified in th32ProcessID in the snapshot. To enumerate the modules, see Module32First. If the function fails with ERROR_BAD_LENGTH, retry the function until it succeeds. 64-bit Windows:  Using this flag in a 32-bit process includes the 32-bit modules of the process specified in th32ProcessID, while using it in a 64-bit process includes the 64-bit modules. To include the 32-bit modules of the process specified in th32ProcessID from a 64-bit process, use the TH32CS_SNAPMODULE32 flag.
TH32CS_SNAPMODULE32 = 0x00000010 -- Includes all 32-bit modules of the process specified in th32ProcessID in the snapshot when called from a 64-bit process. This flag can be combined with TH32CS_SNAPMODULE or TH32CS_SNAPALL. If the function fails with ERROR_BAD_LENGTH, retry the function until it succeeds.
TH32CS_SNAPPROCESS  = 0x00000002 -- Includes all processes in the system in the snapshot. To enumerate the processes, see Process32First.
TH32CS_SNAPTHREAD   = 0x00000004 -- Includes all threads in the system in the snapshot. To enumerate the threads, see Thread32First. To identify the threads that belong to a specific process, compare its process identifier to the th32OwnerProcessID member of the THREADENTRY32 structure when enumerating the threads.

INVALID_HANDLE_VALUE = 0xFFFFFFFFFFFFFFFF

ERROR_ALREADY_EXISTS    = 183       -- Cannot create a file when that file already exists.
ERROR_PATH_NOT_FOUND    = 3         -- The system cannot find the path specified.
ERROR_MORE_DATA         = 0xEA      -- More data is available.
ERROR_FILE_NOT_FOUND    = 2         -- The system cannot find the file specified.
ERROR_ACCESS_DENIED     = 5         -- Access is denied.
ERROR_NO_MORE_FILES     = 0x12      -- There are no more files.
ERROR_SUCCESS           = 0         -- :slight_smile:

-- [[ HKEY PREDEFINED KEYS ]] --
HKEY_CLASSES_ROOT         =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000000))
HKEY_CURRENT_CONFIG       =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000005))
HKEY_CURRENT_USER         =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000001))
HKEY_LOCAL_MACHINE        =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000002))
HKEY_PERFORMANCE_DATA     =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000004))
HKEY_PERFORMANCE_NLSTEXT  =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000060))
HKEY_PERFORMANCE_TEXT     =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000050))
HKEY_USERS                =   ffi.cast("HKEY", ffi.cast("uintptr_t", 0x80000003))

-- [[ dwFlags ]] --
RRF_RT_ANY                =   0x0000ffff
RRF_RT_DWORD              =   0x00000018
RRF_RT_QWORD              =   0x00000048
RRF_RT_REG_BINARY         =   0x00000008
RRF_RT_REG_DWORD          =   0x00000010
RRF_RT_REG_EXPAND_SZ      =   0x00000004
RRF_RT_REG_MULTI_SZ       =   0x00000020
RRF_RT_REG_NONE           =   0x00000001
RRF_RT_REG_QWORD          =   0x00000040
RRF_RT_REG_SZ             =   0x00000002
RRF_NOEXPAND              =   0x10000000
RRF_ZEROONFAILURE         =   0x20000000
RRF_SUBKEY_WOW6464KEY     =   0x00010000
RRF_SUBKEY_WOW6432KEY     =   0x00020000

local utils = {
    FindProcessByName = function(self, name)
        local return_value = false

        local lppe = ffi.new("PROCESSENTRY32[1]")
        lppe[0].dwSize = ffi.sizeof("PROCESSENTRY32")
        local hSnapshot = ffi.cast("HANDLE", ffi.C.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0))

        local Process32First_result = ffi.C.Process32First(hSnapshot, ffi.cast("LPPROCESSENTRY32", lppe))
        if(Process32First_result == 1) then
            while(ffi.C.Process32Next(hSnapshot, ffi.cast("LPPROCESSENTRY32", lppe)) == 1) do
                if(ffi.string(lppe[0].szExeFile) == name) then 
                    return_value = true
                    goto FINISH_FINDPROCESSBYNAME
                end
            end

            if(ffi.C.GetLastError() == ERROR_NO_MORE_FILES) then
                return_value = false
                goto FINISH_FINDPROCESSBYNAME
            else
                error(string.format("Failed to get Process32Next. (%s)", ffi.C.GetLastError()))
            end
        else
            error(string.format("Failed to get Process32First. (%s)", ffi.C.GetLastError()))
        end

        -- We need to clean up the handles after ourselves, so we can't return early.
        ::FINISH_FINDPROCESSBYNAME::
        ffi.C.CloseHandle(hSnapshot)
        return return_value
    end,

    GetOpenFile = function(self, filter, title)
        local lpstrFile = ffi.cast("LPSTR", ffi.new("char[?]", 512))
        local nMaxFile = ffi.cast("DWORD", 512)

        local unnamedParam1 = ffi.new("OPENFILENAMEA[1]")
        unnamedParam1[0].lStructSize = ffi.cast("DWORD", ffi.sizeof("OPENFILENAMEA"))
        unnamedParam1[0].lpstrFilter = table.concat(filter, "\0") .. "\0\0"
        unnamedParam1[0].lpstrFile = lpstrFile
        unnamedParam1[0].nMaxFile = nMaxFile
        unnamedParam1[0].lpstrTitle = title

        local GetOpenFileNameA_return_value = comdlg32.GetOpenFileNameA(ffi.cast("LPOPENFILENAMEA", unnamedParam1)) 
        if(GetOpenFileNameA_return_value == 0) then
            return nil, comdlg32.CommDlgExtendedError()
        else
            return ffi.string(lpstrFile)
        end
    end,

    DoesFileExist = function(self, path)
        local file, err = io.open(path, "rb")
        if(file) then 
            io.close(file)
            return true 
        end

        return false 
    end,

    RenameFile = function(self, original_path, new_path)
        local r_result, r_error = os.rename(original_path, new_path)
        if(not r_result) then 
            error(string.format("Failed to rename file %s to %s", original_path, new_path))
        end
    end,

    ReadFile = function(self, path)
        local file, err = io.open(path, "rb")
        if(not file) then
            error(string.format("ReadFile - An unknown error has occured. %s", err))
        end

        local data = file:read("*a"); file:close()
        return data
    end,

    DeleteFile = function(self, path)
        path = path:sub(1, 255)

        local pdata = ffi.cast("char*", ffi.new("char[?]", #path + 1))
        ffi.copy(pdata, path)
        
        local return_value = ffi.C.DeleteFileA(pdata)
        if(return_value == 0) then
            local extended_error_info = ffi.C.GetLastError()
            return extended_error_info
        end

        return nil
    end,

    RemoveDirectory = function(self, path)
        path = path:sub(1, 255)

        local pdata = ffi.cast("char*", ffi.new("char[?]", #path + 1))
        ffi.copy(pdata, path)
        
        local return_value = ffi.C.RemoveDirectoryA(pdata)
        if(return_value == 0) then
            local extended_error_info = ffi.C.GetLastError()
            return extended_error_info
        end

        return nil
    end,

    ChecksumSHA256 = function(self, path)
        local file = self:ReadFile(path)
        return love.data.encode("string", "hex", love.data.hash("data", "sha256", file))
    end,

    -- Nil means the directory was created successfully
    CreateDirectory = function(self, path)
        path = path:sub(1, 255)

        local pdata = ffi.cast("char*", ffi.new("char[?]", #path + 1))
        ffi.copy(pdata, path)
        
        local return_value = ffi.C.CreateDirectoryA(pdata, nil)
        if(return_value == 0) then
            local extended_error_info = ffi.C.GetLastError()
            return extended_error_info
        end

        return nil
    end,

    RegistryGetString = function(self, hkey, lpSubKey, lpValue)
        local pvData_len = 1024

        while(true) do
            local pdata = ffi.cast("char*", ffi.new("char[?]", pvData_len))
            local plen = ffi.new("DWORD[1]", pvData_len)

            local return_value = ffi.C.RegGetValueA(
                hkey,
                lpSubKey,
                lpValue,
                RRF_RT_ANY,
                nil,
                pdata,
                plen
            )

            if(return_value == ERROR_MORE_DATA) then 
                pvData_len = pvData_len * 2 
            elseif(return_value == ERROR_SUCCESS) then 
                return ffi.string(pdata) 
            elseif(return_value == ERROR_FILE_NOT_FOUND) then
                return nil
            else
                error(string.format("RegistryGetString - An unknown error has occured. %s", return_value))
            end
        end
    end
}

return utils