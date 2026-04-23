# Firebase Key Rotation Playbook

**Applies to:** `toodles-capture` Firebase project
**Triggered by:** TDV-85 (Subproject F of the v1.1 roadmap) — the `GoogleService-Info.plist` with API keys was tracked in git history through 2026-04-23. Any key from that period must be assumed compromised and rotated before v1.1 ships.

## Immediate actions (Danny)

These must be done in the Firebase Console. Claude can't do them — they require the project owner's session.

### 1. Rotate the Web API key

1. Go to <https://console.cloud.google.com/apis/credentials>.
2. Find the "Browser key (auto created by Firebase)" for project `toodles-capture`.
3. Note the current key (for post-rotation comparison, then stop using it).
4. Click **Regenerate key**. Confirm.
5. The new key is now active; the old key still works briefly.

### 2. Restrict the new key

While on the credentials page for the new key:

1. Click **Edit API key** on the new Browser key.
2. Under **Application restrictions**, choose **iOS apps** and add bundle ID `edu.csuf.toodles`.
3. Under **API restrictions**, select **Restrict key** and enable only:
   - Identity Toolkit API (for Firebase Auth REST)
   - Cloud Firestore API
   - Firebase Installations API
   - Firebase Remote Config API (if you use it later)
4. Save.

### 3. Download the fresh plist

1. Firebase Console → Project Settings (gear icon) → General tab.
2. Scroll to Your apps → iOS → `edu.csuf.toodles`.
3. Click **GoogleService-Info.plist** to download.
4. Move it into `toodles/Toodles/Resources/GoogleService-Info.plist`. Do **not** commit — it's gitignored.

### 4. Add the plist as a GitHub Actions secret

So CI builds can talk to Firebase without committing the file:

```bash
base64 -i toodles/Toodles/Resources/GoogleService-Info.plist -o plist.b64
# On macOS/Linux; on Windows PowerShell:
#   [Convert]::ToBase64String([IO.File]::ReadAllBytes("Toodles/Resources/GoogleService-Info.plist")) | Set-Clipboard
```

Then in the GitHub repo:
1. Settings → Secrets and variables → Actions → New repository secret
2. Name: `GOOGLE_SERVICE_INFO_PLIST_B64`
3. Secret: paste the base64 content from above.

The `.github/workflows/ios-build.yml` workflow already reads this secret and writes the plist during the build.

### 5. Revoke the old key (after 48 hours)

Give any in-flight Appetize sessions or builds a buffer, then:

1. Same credentials page in Google Cloud Console.
2. Locate the old key (if still listed).
3. Click the trash icon → **Delete**.

## Why the restrictions matter

Firebase rules (`firebase/firestore.rules`) guard the data, but the API key protects against API quota abuse and ensures only your app can make auth requests. The four-step process above limits blast radius if the key leaks again:

- Bundle ID restriction → key only works from `edu.csuf.toodles`.
- API restriction → key can't pivot into GCP services like Cloud Functions or Pub/Sub.
- Rotation on detection → minimizes exposure window.

## Future: prevent regression

Add a pre-push git hook that blocks pushing any file named `GoogleService-Info.plist` (not the `.example`). `.gitignore` already catches it, but hooks protect against someone running `git add -f`.
