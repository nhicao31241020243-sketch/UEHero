# Event data seeder

The app only reads `events` from Cloud Firestore. The checked-in
[`events_seed.json`](./events_seed.json) is an administrative seed file, not a
Flutter asset.

1. In Firebase Console, select **Project settings → Service accounts →
   Generate new private key**. Save the key locally as
   `tools/service-account.json`; this filename is ignored by Git. Never commit
   or share the key.
2. From the repository root, set Application Default Credentials and install
   the seeder dependency using Node.js 22 or newer:

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = "$PWD\tools\service-account.json"
   Push-Location tools
   npm install
   npm run seed -- --confirm
   Pop-Location
   Remove-Item Env:GOOGLE_APPLICATION_CREDENTIALS
   ```

   The `--confirm` flag is required because the script writes/upserts live
   Firestore documents. Review the seed file and obtain approval before running
   it.
3. To deploy Firestore rules, select the intended Firebase project with
   `firebase use --add`, then run `firebase deploy --only firestore:rules`.

Before opening Events in the app, run `flutterfire configure`, enable Anonymous
Authentication and create the Firestore database in Firebase Console. Keep the
generated Firebase client configuration in the project as instructed by
FlutterFire; do not use the service-account key in the app.
