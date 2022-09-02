# Detection-Updates
With this script we will determine which is the last month that the equipment was updated correctly.
- The script automatically picks up the KBs released from the official Microsoft website. 
- It calculates when is Patch Tuesday of each month. 
- Tired of the patch report in Intune being set to 0 every Patch Tuesday? With this script you can define how many months without patching are valid for your organisation. By default it is set to 2 so that it gives as good as good teams that have     the patch that is currently being distributed and the previous one. 
- Store in Windows Registry the month and year for the last patch valid.

# Repair-1
This is a compilation of the least aggressive and effective methods to repair Windows Update.
What it does:
    - Delete all qmgr.dat files to clear stuck Bits jobs
    - Backing up the Windows Update cache folders to generate the cache again
    - Resets security descriptors for BITS and Windows Update services 
    - Re-register the DLLs related to the Windows Update Agent.
    - Clean WSUS entries from the Windows registry
    - Reset ACL for WUA
    - Repair damaged files with DISM


# Repair-2
Change temporarily Energy options to High Performance . When finish restore originals energy options.
Initiates and forces the download of the patch from the internet using Microsoft.Update.SystemInfo, can also be done against a WSUS server


# Repair-3 !!!! In development!!!!
Install patch using Cab file with DISM




Author:  Alejandro Aguado Garcia  
Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/  
Twitter: @Alejand94399487  
