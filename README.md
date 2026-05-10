# Active Directory Home Lab — Domain Setup, AGDLP, Group Policy, and Troubleshooting

This project is an Active Directory home lab built from scratch in VMware, with Windows Server 2025 on the domain controller and Windows 11 Pro on the client. The setup is a single-domain environment (homelab.local) with a department-based Organizational Unit structure containing roughly 50 users across six departments — Accounting, Executives, HR, IT, Marketing, and Sales. I configured multiple Group Policy Objects covering a login banner, fine-grained password policies, drive mappings via item-level targeting, and a workstation security baseline, and implemented AGDLP-based file server permissions for principle-of-least-privilege access control. The project closes with a documented troubleshooting case study that walks through diagnosis and resolution of a realistic helpdesk ticket.

## Architecture

[NETWORK TOPOLOGY DIAGRAM HERE]

The lab runs on VMware Workstation, with both VMs hosted on a single physical machine. The Domain Controller (FileServer01) also serves as the file server in this setup — in production these would typically be separate hosts, but consolidating them keeps the lab focused on Active Directory itself rather than infrastructure plumbing. The Windows 11 client (Pluto) is joined to the homelab.local domain and authenticates against the DC for logon and file access.

### Lab Environment

| Component | Hostname | IP Address | OS | Roles |
|-----------|----------|------------|----|-------|
| Domain Controller | `FileServer01` | 192.168.253.129 | Windows Server 2025 | AD DS, DNS, File Server |
| Workstation | `Pluto` | 192.168.253.130 | Windows 11 Pro | Domain-joined client |

- **Domain:** `homelab.local`
- **Hypervisor:** VMware Workstation

## Project Goals

Coming from a background in personal training and business development, 
I built this lab to translate the Active Directory knowledge from my CompTIA 
A+ certification into demonstrable, hands-on configuration. Active Directory 
is the foundation of enterprise identity, access management, and security, 
which is why I prioritized it as my first hands-on project as I transition into IT.

This project specifically demonstrates:

- **Active Directory design** — OU structure, Global and Domain Local 
security groups, and bulk user provisioning across six departments 
(~50 users)
- **Group Policy mechanics** — domain-level and OU-scoped GPOs, 
Item-Level Targeting on drive maps, and Fine-Grained Password Policies 
with tiered precedence
- **File server access control** — AGDLP-based NTFS permissions with 
explicit inheritance flags and principle-of-least-privilege scoping
- **PowerShell automation** — idempotent scripts for OU creation, 
group provisioning, bulk user creation, and ACL management
- **Troubleshooting methodology** — documented case study tracing a 
user-reported issue through diagnostic tools (`gpresult`, ADUC, Event 
Viewer, Kerberos cache analysis) to root cause and resolution

The USA OU anchors the hierarchy and allows future expansion to additional 
regions without restructuring. Below it, separate OUs for Users, Workstations, 
Servers, and Groups support targeted GPO scoping — a workstation security 
baseline can apply to the Workstations OU without affecting servers, and 
drive-mapping GPOs can target the Users OU without affecting computer 
accounts. The six department sub-OUs under Users enable per-department GPO 
targeting and lay groundwork for delegated administration (e.g., granting 
password-reset rights to a department lead without making them a Domain Admin). 
The `_Admin` OU is reserved for privileged accounts and admin groups — the 
leading underscore sorts it visually to the top, and the structural separation 
keeps high-privilege objects distinct from standard users, a recommended 
security-hardening pattern.

Phase 1 promoted a fresh Windows Server 2025 install to a Domain 
Controller, established the `homelab.local` domain, and configured 
the DC to also host DNS and the File and Storage Services role — 
a deliberate consolidation for lab simplicity. The Windows 11 client 
(`Pluto`) was joined to the domain and authenticates against the DC 
for all logon and resource access. Validation used `Get-ADDomain` 
to confirm domain configuration and `dcdiag` to verify directory health.

![Server Manager dashboard showing AD DS, DNS, and File Storage roles installed on the DC](screenshots/phase1/phase1_03-server-manager-roles.png)
*Server Manager confirming the three roles installed on the domain controller.*

![Pluto's System properties showing it is joined to homelab.local](screenshots/phase1/phase1_07-client-system-properties.png)
*Client (`Pluto`) joined to `homelab.local` and authenticating as a domain user.*

Phase 2 transformed the flat default AD into a structured environment. The 
OU hierarchy was built out with five sub-OUs under USA (`_Admin`, `Groups`, 
`Servers`, `Users`, `Workstations`), and six department sub-OUs under Users 
(Accounting, Executives, HR, IT, Marketing, Sales). Six Global Security 
groups — one per department — were created in the Groups OU to serve as the 
identity layer for AGDLP. The centerpiece was a PowerShell script that 
bulk-provisioned 50 explorer-themed users from a structured data source: 
it generated consistent usernames (first-initial + lastname), placed each 
user in the correct department OU, set a temporary password with 
`ChangePasswordAtLogon` enforced, and added them to their department 
security group. The script was idempotent — safe to re-run — and produced 
49 created and 1 skipped (an existing user).

![ADUC showing the new OU structure](screenshots/phase2/phase2_01-ou-structure-after.png)
*The redesigned OU hierarchy: top-level USA OU with sub-OUs separated by object type, plus department-specific sub-OUs under Users.*

![Bulk user creation script output](screenshots/phase2/phase2_05-script-execution.png)
*PowerShell output from the bulk user creation script — 49 users created, 1 correctly skipped (idempotency check), 0 failed.*

![ADUC showing populated IT OU](screenshots/phase2/phase2_08-aduc-populated-ou.png)
*The IT department OU populated with explorer-themed users after the script ran (Ernest Shackleton, Buzz Aldrin, Yuri Gagarin, etc.).*

### Phase 3 — Group Policy

Phase 3 created four GPOs at three different scopes (domain, OU, and group 
via security filtering) plus two Fine-Grained Password Policies, then 
verified the entire stack with `gpresult`.

The phase produced:

- **`DOM_AllUsers_LoginBanner`** — domain-level interactive legal warning 
shown before login
- **`OU_Workstations_SecurityBaseline`** — three security settings applied 
to the Workstations OU: 10-minute machine inactivity lock, USB removable 
disk write-deny, and LLMNR disabled
- **`OU_Users_DriveMappings`** — seven drive map items (six department-
specific H: drives plus a Public P:), routed to the correct user via 
Item-Level Targeting on group membership
- **`PSO_Standard_Users` / `PSO_Privileged_Users`** — Fine-Grained Password 
Policies with tiered precedence; Privileged (50) wins over Standard (100) 
for users in IT and Executives

Verification used `gpresult /h` to generate an HTML report tracing each 
applied setting back to its source GPO.

![Login banner on client](screenshots/phase3/phase3_04-login-banner-on-client.png)
*Domain-wide login banner appearing on the client (`Pluto`) before the password prompt — proof of policy propagation from DC to client.*

![PSO enforcement demo](screenshots/phase3/phase3_07-pso-enforcement-demo.png)
*PSO enforcement in action: the same 14-character password rejected for `eshackleton` (Privileged PSO, 16-character minimum) but accepted for `aketchum` (Standard PSO, 12-character minimum) — demonstrates tiered precedence working correctly.*

![ILT targeting editor](screenshots/phase3/phase3_12-ilt-targeting-editor.png)
*Item-Level Targeting condition on the HR drive map: the H: drive mapping applies only to users who are members of `HOMELAB\HR`. The same GPO contains six similar items for the other departments, each with its own targeting condition.*

![gpresult HTML report](screenshots/phase3/phase3_19-gpresult-setting-trace.png)
*`gpresult` HTML report tracing the login banner setting back to its source GPO (`DOM_AllUsers_LoginBanner`) — end-to-end verification that the policy applied as designed.*

### Phase 4 — File Server Permissions (AGDLP)

An audit of existing NTFS permissions across the seven department subfolders 
revealed two real-world issues: the HR group had Modify access on every 
folder (inherited from the parent — a classic oversharing pattern), and 
three departments (Executives, Marketing, Sales) had no permissions on their 
own folders at all. Rather than patching individual ACLs, the entire access 
model was rebuilt using AGDLP — Accounts go into Global groups, Global 
groups are nested in Domain Local groups, and Domain Local groups receive 
permissions on the resource.

[AGDLP DIAGRAM HERE]

The implementation began with a teardown script that removed all `HOMELAB\*` 
ACEs and normalized inheritance to a clean baseline, leaving only 
infrastructure entries (Administrators, SYSTEM, CREATOR OWNER) on each 
subfolder. Seven Domain Local groups (`DL_Accounting_Modify`, `DL_HR_Modify`, 
etc.) were created with the appropriate Global group nested inside each, and 
these DL groups were applied directly to the NTFS ACLs with Modify rights 
and inheritance to subfolders and files. The parent `C:\CompanyData` 
received `Domain Users` with Read & Execute on the parent only (no 
inheritance) so users can navigate down to their department folder without 
gaining unintended access to others. Verification used two non-admin test 
users (`aketchum` from Accounting, `ramundsen` from Executives) — each 
could read and write to their own department folder, were denied access to 
other departments, and could access Public.

![Post-AGDLP ACL audit](screenshots/phase4/phase4_06b-post-agdlp-acl-audit.png)
*Every subfolder now shows the same four-ACE pattern: three infrastructure entries (CREATOR OWNER, SYSTEM, BUILTIN\Administrators) and one DL_*_Modify group for department access. Predictable and consistent across the entire share.*

![aketchum write success](screenshots/phase4/phase4_08-aketchum-accounting-write-success.png)
*Test user `aketchum` (Accounting) successfully writes a file to H:\ — proves the AGDLP chain `aketchum` → `Accounting` → `DL_Accounting_Modify` → NTFS Modify works end-to-end for a non-admin user.*

![aketchum HR denied](screenshots/phase4/phase4_09-aketchum-hr-denied.png)
*Same user blocked when navigating to a different department's folder via UNC path. Paired with the previous screenshot, this captures the access matrix in two images — works where it should, fails where it should.*

![ramundsen write success](screenshots/phase4/phase4_12-ramundsen-executives-write-success.png)
*Test user `ramundsen` (Executives) writes to her department folder — particularly significant because Executives had no permissions on its folder before the AGDLP rebuild. This screenshot represents a bug fix from the original audit, not just a configuration step.*

### Phase 5 — Troubleshooting Case Study

Phase 5 documented a simulated helpdesk ticket: a user reported their H: 
drive was missing while P: still worked. Diagnosis used `whoami /groups`, 
`gpresult`, and ADUC to compare the user's session token against AD state. 
An interesting subtlety surfaced — the token still listed the old group 
membership even after sign-out, requiring a full reboot to clear cached 
credentials and confirm the diagnosis. Root cause traced through the AGDLP 
chain: the user had been removed from the `Executives` Global group, which 
broke `Executives → DL_Executives_Modify → NTFS Modify` and caused the 
drive map's Item-Level Targeting to skip the H: item. Resolution was a 
single ADUC change — re-adding the user to the group restored access on 
next login.

For the full diagnostic writeup, see 
[Case Study: H: Drive Missing After Login](docs/case-study-h-drive-missing.md).

![Symptom: H: drive missing](screenshots/phase5/phase5_02-symptom-h-drive-missing.png)
*The reported symptom: File Explorer shows the P: drive (Public) and local C: drive, but the H: (Executives Department) drive is missing despite the user having had access previously.*

![Fix: H: drive restored](screenshots/phase5/phase5_07-h-drive-restored.png)
*After re-adding the user to the Executives Global group and signing back in, both H: and P: are visible. End-to-end proof that the AGDLP chain was the root cause and the fix worked.*

## Skills Demonstrated

### Active Directory
- Domain controller deployment with AD DS and integrated DNS
- OU hierarchy design with object-type and departmental separation
- Global and Domain Local security group strategy
- Bulk user provisioning via PowerShell automation (~50 users across 6 departments)

### Group Policy
- GPO design and scoping at domain, OU, and group levels
- Group Policy Preferences with Item-Level Targeting
- Fine-Grained Password Policies with tiered precedence
- Workstation security baseline (inactivity lock, removable storage, LLMNR)
- gpresult-based verification and HTML reporting

### File Server & Access Control
- AGDLP-based NTFS permissions model
- Domain Local groups for resource-tier access control
- NTFS inheritance flags (ContainerInherit, ObjectInherit)
- Principle of least privilege applied through narrow permission scoping

### PowerShell Automation
- Active Directory cmdlets (Get/New/Set/Add-ADUser, ADGroup, ADOrganizationalUnit)
- ACL manipulation (Get-Acl, Set-Acl, .NET FileSystemAccessRule)
- Idempotent script design with try/catch and existence checks
- Pipeline filtering with Where-Object

### Troubleshooting Methodology
- Diagnostic toolchain (gpresult, dcdiag, whoami /groups, ADUC, Event Viewer)
- Hypothesis-driven investigation: symptom → diagnosis → root cause → fix
- Kerberos token and credential cache analysis
- Incident documentation in formal case-study format

## A Note on Tooling and AI Assistance

This lab was built with significant AI assistance for PowerShell scripting 
and architectural guidance. I designed the lab structure, made the design 
decisions (single-DC topology, AGDLP permissions model, OU layout, GPO scope 
choices), executed every step on the live system, and verified results at 
every stage. The PowerShell scripts in `/scripts` reflect repeatable, 
idempotent patterns suitable for real infrastructure work — I can read them, 
explain them, and modify them, but I would not claim PowerShell expertise 
at this stage of my career.

The primary learning outcome was conceptual: Active Directory architecture, 
Group Policy mechanics, the AGDLP authorization model, and structured 
troubleshooting methodology. This project is a portfolio of demonstrable 
skills, not a claim of mastery.