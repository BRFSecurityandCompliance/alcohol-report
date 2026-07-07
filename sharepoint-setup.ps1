<#
============================================================================
 sharepoint-setup.ps1 — สร้าง SharePoint lists สำหรับระบบรายงานแอลกอฮอล์
----------------------------------------------------------------------------
 ต้องมี PnP.PowerShell:
     Install-Module PnP.PowerShell -Scope CurrentUser

 เชื่อมต่อไซต์ S&C ก่อนรัน (แก้ URL เป็นของคุณ):
     Connect-PnPOnline -Url "https://bevchainthailand.sharepoint.com/teams/SecurityComplianceDept" -Interactive

 หมายเหตุ: บาง tenant บล็อก PnP Management Shell app —
 ถ้า -Interactive ใช้ไม่ได้ ให้ใช้ App Registration (Entra ID) หรือสร้าง list เองตามตารางท้ายไฟล์
============================================================================
#>

# ---------- 1) Routing list: ไซต์ -> อีเมลผู้จัดการ ----------
# Title (มีอยู่แล้ว) = ชื่อไซต์ เช่น LLKDC
$routing = "AlcoholTest_SiteRouting"
if (-not (Get-PnPList -Identity $routing -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $routing -Template GenericList -OnQuickLaunch | Out-Null
    Add-PnPField -List $routing -DisplayName "ManagerEmail" -InternalName "ManagerEmail" -Type Text -AddToDefaultView | Out-Null
    Add-PnPField -List $routing -DisplayName "CCEmail"      -InternalName "CCEmail"      -Type Note -AddToDefaultView | Out-Null
    Write-Host "✅ สร้าง $routing แล้ว (Title=Site, ManagerEmail, CCEmail)" -ForegroundColor Green
} else { Write-Host "ℹ️ มี $routing อยู่แล้ว ข้าม" -ForegroundColor Yellow }

# ---------- 2) Log list: บันทึกทุกรายงาน (สำหรับ EGM report / Power BI) ----------
# Title = CaseId เช่น ALC-20260706-...
$log = "AlcoholTest_Log"
if (-not (Get-PnPList -Identity $log -ErrorAction SilentlyContinue)) {
    New-PnPList -Title $log -Template GenericList -OnQuickLaunch | Out-Null

    $fields = @(
        @{ D = "Site";        T = "Text" },
        @{ D = "TestDate";    T = "DateTime" },
        @{ D = "PersonType";  T = "Text" },
        @{ D = "FullName";    T = "Text" },
        @{ D = "Company";     T = "Text" },
        @{ D = "LicensePlate";T = "Text" },
        @{ D = "Result1";     T = "Text" },
        @{ D = "Time1";       T = "Text" },
        @{ D = "Result2";     T = "Text" },
        @{ D = "Time2";       T = "Text" },
        @{ D = "Severity";    T = "Text" },
        @{ D = "PhotoUrl";    T = "Note" },
        @{ D = "Reporter";    T = "Text" },
        @{ D = "Notes";       T = "Note" },
        @{ D = "SubmittedAt"; T = "DateTime" }
    )
    foreach ($f in $fields) {
        Add-PnPField -List $log -DisplayName $f.D -InternalName $f.D -Type $f.T -AddToDefaultView | Out-Null
    }
    Write-Host "✅ สร้าง $log แล้ว (Title=CaseId + $($fields.Count) คอลัมน์)" -ForegroundColor Green
} else { Write-Host "ℹ️ มี $log อยู่แล้ว ข้าม" -ForegroundColor Yellow }

Write-Host "`n🔒 อย่าลืม: จำกัดสิทธิ์เข้าถึง 2 list นี้ (ข้อมูลส่วนบุคคล PDPA)" -ForegroundColor Cyan

<#
============================================================================
 ถ้าสร้างเองด้วยมือ — โครงคอลัมน์
----------------------------------------------------------------------------
 AlcoholTest_SiteRouting
   Title (Single line)      = ชื่อไซต์  (ตรงกับ dropdown ในฟอร์มเป๊ะ)
   ManagerEmail (Single line)
   CCEmail (Multiple lines)  = คั่นด้วย ;

 AlcoholTest_Log
   Title (Single line)      = CaseId
   Site, PersonType, FullName, Company, LicensePlate,
   Result1, Time1, Result2, Time2, Severity, Reporter  = Single line
   TestDate, SubmittedAt    = Date and Time
   PhotoUrl, Notes          = Multiple lines
============================================================================
#>
