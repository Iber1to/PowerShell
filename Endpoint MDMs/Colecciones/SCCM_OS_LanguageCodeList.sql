/*
  This query retrieves all unique values for the "OSLanguage" field from the operating systems detected by SCCM.
  It joins the SMS_R_System table with the SMS_G_System_OPERATING_SYSTEM table based on the ResourceId.
  The purpose of this query is to display distinct operating system languages for all devices managed by SCCM.
  
  Only non-null OSLanguage values are included in the results.
  
  Example of output values could include:
  - 1033 (English - United States)
  - 1031 (German - Germany)
  - 3082 (Spanish - Spain)
  You can view a full list in https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oe376/6c085406-a698-4e12-9d4d-c3b0ee3dbc4a
*/
select DISTINCT SMS_G_System_OPERATING_SYSTEM.OSLanguage
from SMS_R_System 
inner join SMS_G_System_OPERATING_SYSTEM 
on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
where SMS_G_System_OPERATING_SYSTEM.OSLanguage IS NOT NULL
