# Case Study: User Reports H: Drive Missing After Login

## The Ticket
A user (Roald Amundsen, Executives department) reported that his H: drive was missing after he signed in. The P: drive (the shared Public drive) was still showing up normally. He'd already tried restarting, but that didn't help.

## Initial Thinking
The H: drive comes from a Group Policy that maps it based on the user's department group. So if H: is missing but P: is working, possible causes:

- The Group Policy that maps H: didn't apply
- The user might not be in the right security group anymore
- The file server might not be reachable
- Permissions on the folder might be broken

I had a hunch it was a group membership issue, but I wanted to verify rather than assume.

## How I Diagnosed It

### Step 1: Confirm the problem on the client

On Pluto, I opened Command Prompt and ran:

```
net use
```

This lists what network drives are currently mapped. Output confirmed only P: was mapped — no H:. So the symptom was real, not a perception issue.

### Step 2: Check the user's group memberships from the session

While logged in as the user, I ran:

```
whoami /groups
```

The output showed they were in the Executives group, which is what's supposed to trigger the H: drive mapping. This was confusing — if they're in the group, the drive should be mapping. Turned out this was a clue, not the final answer.

### Step 3: Check what Group Policy actually applied

```
gpresult /r /scope:user
```

This shows which GPOs got applied during the user's login. The drive mappings GPO showed as applied, but H: specifically wasn't getting mapped. That meant the group condition for H: wasn't matching when the policy ran, even though `whoami /groups` was showing the user in Executives now.

### Step 4: Check Active Directory itself

On the server, I opened ADUC, looked up Roald, and checked his group memberships from the directory side. He was NOT in the Executives group. So the user's logged-in session was showing one thing, but the actual current state in AD said something different.

The user's group memberships when they logged in were different from what's in AD right now. Something had been changed AFTER they logged in.

### Step 5: Confirm the caching behavior

When a user logs in, Windows grabs a snapshot of their group memberships and uses that snapshot for the whole session. If their groups change while they're logged in, the session doesn't automatically pick up the change. Even signing out and back in didn't fully clear it for this user — I had to do a full reboot to force a completely fresh login and verify the cached info was gone.

## What Was Actually Wrong

The user had been removed from the Executives security group at some point after his last login. The Group Policy that maps the H: drive checks "is this user in Executives?" — when the answer became "no," the H: drive simply didn't get mapped. There's no error message; the drive just doesn't show up. P: still worked because it's mapped for everyone, not based on group membership.

## How I Fixed It

1. Added the user back to the Executives security group in ADUC
2. Had the user sign out and sign back in to refresh their session, then do a full reboot
3. H: drive came back automatically
4. Verified by having the user open a file in the H: drive and save a change

## What I Learned

- A user's "groups during their current session" can be different from "groups in AD right now." The session is a snapshot from when they logged in.
- Group Policy that depends on group membership only re-checks at login — that's why a fresh login is often the fix.
- "Have you tried restarting?" isn't just a meme. Restarting forces a clean login, which clears cached membership info and forces a fresh check against the server. It's a legitimate diagnostic step.
- `gpresult` is one of the most useful troubleshooting tools for figuring out why a policy did or didn't apply. It tells you exactly what happened.
- When something works for some users but not others, the difference is almost always either group membership or permissions. That's the first place to check.

## Tools I Used

- **ADUC** — to check the user's group memberships in the directory
- **Command Prompt** — `net use`, `whoami /groups`, `gpresult /r /scope:user`
- **Just signing in and out** — to observe what the session showed vs. what AD said
