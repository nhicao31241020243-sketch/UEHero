import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';

if (!process.argv.includes('--confirm')) {
  throw new Error(
    'This writes to Cloud Firestore. Re-run with --confirm after reviewing events_seed.json.',
  );
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  throw new Error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to a local service-account JSON path.',
  );
}

const directory = dirname(fileURLToPath(import.meta.url));
const seedPath = resolve(directory, 'events_seed.json');
const events = JSON.parse(await readFile(seedPath, 'utf8'));

if (!Array.isArray(events)) {
  throw new TypeError('events_seed.json must contain a JSON array.');
}

const timestampFields = [
  'registrationOpen',
  'registrationDeadline',
  'eventStart',
  'eventEnd',
  'verifiedAt',
  'createdAt',
  'updatedAt',
];

function toTimestamp(value, field, id) {
  if (value == null) return null;
  if (typeof value !== 'string' || Number.isNaN(Date.parse(value))) {
    throw new TypeError(`Invalid ${field} date for event ${id}.`);
  }
  return Timestamp.fromDate(new Date(value));
}

const seen = new Set();
const records = events.map((event) => {
  if (!event || typeof event !== 'object' || Array.isArray(event)) {
    throw new TypeError('Each seed entry must be an object.');
  }
  if (typeof event.id !== 'string' || !event.id.trim()) {
    throw new TypeError('Every event needs a fixed, non-empty id.');
  }
  if (seen.has(event.id)) {
    throw new TypeError(`Duplicate event id: ${event.id}`);
  }
  seen.add(event.id);
  if (!event.title || !event.organizer || !event.type) {
    throw new TypeError(`Event ${event.id} is missing title, organizer, or type.`);
  }

  const record = { ...event };
  for (const field of timestampFields) {
    record[field] = toTimestamp(event[field], field, event.id);
  }
  record.createdAt ??= Timestamp.now();
  record.updatedAt ??= Timestamp.now();
  return record;
});

initializeApp({ credential: applicationDefault() });
const firestore = getFirestore();
firestore.settings({ ignoreUndefinedProperties: false });

for (let offset = 0; offset < records.length; offset += 450) {
  const batch = firestore.batch();
  for (const event of records.slice(offset, offset + 450)) {
    const { id, ...data } = event;
    data.id = id;
    data.updatedAt = FieldValue.serverTimestamp();
    batch.set(firestore.collection('events').doc(id), data, { merge: true });
  }
  await batch.commit();
}

console.log(`Upserted ${records.length} reviewed event documents.`);
