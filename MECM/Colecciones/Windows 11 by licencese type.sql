/*
  The SMS_G_System_OPERATING_SYSTEM.Caption property can have various values depending on the operating system version.
  Below are some examples of possible values:

  - "Microsoft Windows 10 Enterprise"
  - "Microsoft Windows 10 Pro"
  - "Microsoft Windows 11 Enterprise"
  - "Microsoft Windows 11 Enterprise Evaluation"
  - "Microsoft Windows 11 Pro"
  - "Microsoft Windows Server 2016 Datacenter"
  - "Microsoft Windows Server 2019 Datacenter"
  - "Microsoft Windows Server 2022 Datacenter"

  You can use this property in your query to filter systems by their operating system type and version.
  Example:
  where SMS_G_System_OPERATING_SYSTEM.Caption = "Microsoft Windows 11 Pro"
*/

select * 
from  SMS_R_System 
inner join SMS_G_System_OPERATING_SYSTEM 
on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId 
where SMS_G_System_OPERATING_SYSTEM.Caption = "Microsoft Windows 11 Enterprise"