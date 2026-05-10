## Case Study: User Reports H: Drive Missing After Login

**Reported Symptom**
"User Roald Amundsen (Executives) reports H: drive is missing after 
signing in. P: drive still works. Restart did not resolve."

**Initial Hypotheses**
- Drive mapping GPO failed to apply
- ILT condition not matching (group membership issue)
- File server unreachable from client
- Permissions removed at NTFS layer

**Diagnostic Steps**
1. Confirmed symptom on client: `net use` showed only P:, no H:
2. Checked user's session token: `whoami /groups` showed Executives 
   present (initially misleading — token was stale)
3. Verified GPO application: `gpresult /r /scope:user` showed 
   OU_Users_DriveMappings was applied; ILT had skipped the H: items
4. Compared session token to AD state in ADUC: discovered user had 
   been removed from Executives group at AD level despite token still 
   showing membership
5. Forced credential refresh: `klist purge` + sign out insufficient; 
   full reboot required to clear cached credentials
6. Post-reboot token confirmed: Executives no longer present, 
   confirming root cause

**Root Cause**
User was removed from the Executives Global group. This broke the 
AGDLP chain (User → Executives → DL_Executives_Modify → NTFS Modify) 
at the first link. The drive mapping GPO uses Item-Level Targeting 
on Executives group membership, so the H: drive item silently failed 
to apply when the condition no longer matched.

**Resolution**
Re-added user to Executives security group via ADUC. User signed out 
and back in to refresh session token. H: drive remapped automatically 
on next login. Verified file system access by reading and writing to 
H:\ramundsen-test-write.txt.

**Lessons Learned**
- Group membership changes don't take effect until the user 
  re-authenticates; the user's session token is a snapshot from 
  logon time
- Cached credentials can persist beyond a sign-out cycle, requiring 
  more aggressive refresh (klist purge or reboot) in some cases
- "Reboot the workstation" is a legitimate diagnostic step, not just 
  a punchline — it eliminates session, ticket, and credential caching 
  in one action
- ILT in GPP fails silently when conditions don't match — there's 
  no error message to the user, just missing functionality

**Tools Used**
ADUC, GPMC, Command Prompt (`net use`, `whoami /groups`, `klist`, 
`klist purge`, `gpupdate`, `gpresult /r /scope:user`)