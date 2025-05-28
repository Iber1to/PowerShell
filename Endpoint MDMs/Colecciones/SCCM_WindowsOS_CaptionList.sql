/*
  This query retrieves all unique values for the "Caption" field from the operating systems detected by SCCM.
  It joins the SMS_R_System table with the SMS_G_System_OPERATING_SYSTEM table based on the ResourceId.
  The purpose of this query is to display distinct operating system names (captions) for all devices managed by SCCM.
  
  Only non-null Caption values are included in the results.
  
  Example of output values could include:
  - Microsoft Windows 10 Pro
  - Microsoft Windows 11 Enterprise
  - Microsoft Windows Server 2019 Datacenter
*/
select DISTINCT SMS_G_System_OPERATING_SYSTEM.Caption
from SMS_R_System 
inner join SMS_G_System_OPERATING_SYSTEM 
on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
where SMS_G_System_OPERATING_SYSTEM.Caption IS NOT NULL
