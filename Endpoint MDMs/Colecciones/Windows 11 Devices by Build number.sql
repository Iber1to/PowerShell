/*
  This query displays Windows 11 machines with the SCCM client enabled. By removing: and SMS_R_System.Client = "1", 
  we would create a collection for all Windows 11 machines.
  To create a collection for a specific Build, for example 23H2: 
  where SMS_G_System_OPERATING_SYSTEM.BuildNumber = "22631" and SMS_R_System.Client = "1"
*/
select * from  SMS_R_System 
inner join SMS_G_System_OPERATING_SYSTEM 
on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId 
where SMS_G_System_OPERATING_SYSTEM.BuildNumber >= "22000" and SMS_G_System_OPERATING_SYSTEM.BuildNumber < "30000" and SMS_R_System.Client = "1"
