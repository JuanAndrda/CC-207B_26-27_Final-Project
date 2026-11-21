// Fills the local Firebase Emulator with demo accounts and data, so the team
// can try every feature without a real Firebase project.
// Run (with the emulator already running): node tool/seed_emulator.mjs
// Demo logins (password for all: demo1234):
//   farmer@demo.ph (Pedro), buyer@demo.ph (Ana), admin@demo.ph (Admin)

const project = 'demo-agosugnayan';
const auth = 'http://127.0.0.1:9099';
const db = `http://127.0.0.1:8080/v1/projects/${project}/databases/(default)/documents`;
// "Bearer owner" lets this script skip the security rules (emulator only).
const headers = { 'Content-Type': 'application/json', Authorization: 'Bearer owner' };

/** Creates a login and returns its user id. */
async function createUser(email) {
  const res = await fetch(`${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ email, password: 'demo1234', returnSecureToken: true }),
  });
  const data = await res.json();
  if (!data.localId) throw new Error(`Could not create ${email}: ${JSON.stringify(data)}`);
  return data.localId;
}

/** Turns a plain JS value into Firestore's REST format. */
function toFirestore(value) {
  if (value === null) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'number') return { doubleValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(toFirestore) } };
  if (typeof value === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(value)) fields[k] = toFirestore(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

/** Writes one document at path, e.g. "users/abc". */
async function setDoc(path, data) {
  const res = await fetch(`${db}/${path}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(toFirestore(data).mapValue),
  });
  if (!res.ok) throw new Error(`Could not write ${path}: ${await res.text()}`);
}

const daysFromNow = (n) => new Date(Date.now() + n * 86400000);
const now = new Date();

const farmerId = await createUser('farmer@demo.ph');
const buyerId = await createUser('buyer@demo.ph');
const adminId = await createUser('admin@demo.ph');

await setDoc(`users/${farmerId}`, { name: 'Pedro Santos', email: 'farmer@demo.ph', role: 'farmer', town: 'Leon', about: 'Vegetable farmer in Barangay Bucari.', createdAt: now });
await setDoc(`users/${buyerId}`, { name: 'Ana Reyes', email: 'buyer@demo.ph', role: 'buyer', town: 'Iloilo City', about: '', createdAt: now });
await setDoc(`users/${adminId}`, { name: 'Admin', email: 'admin@demo.ph', role: 'admin', town: 'Leon', about: '', createdAt: now });

const crops = [
  ['Tomato', 50, 'kg', 45], ['Eggplant', 30, 'kg', 55], ['Cabbage', 20, 'kg', 40],
  ['Ampalaya', 15, 'kg', 80], ['Kangkong', 40, 'bundle', 15],
];
for (const [i, [crop, quantity, unit, price]] of crops.entries()) {
  await setDoc(`listings/demo${i}`, {
    farmerId, farmerName: 'Pedro Santos', crop, quantity, unit, price, town: 'Leon',
    harvestDate: daysFromNow(2), description: `Fresh ${crop.toLowerCase()} from Leon.`,
    aiAssisted: false, createdAt: new Date(Date.now() - i * 60000),
  });
}

await setDoc('requests/demo1', { buyerId, buyerName: 'Ana Reyes', crop: 'Tomato', quantity: 100, unit: 'kg', targetPrice: 42, town: 'Iloilo City', neededBy: daysFromNow(5), notes: 'For my carinderia, weekly order.', createdAt: now });
await setDoc('requests/demo2', { buyerId, buyerName: 'Ana Reyes', crop: 'Onion', quantity: 25, unit: 'kg', targetPrice: null, town: 'Iloilo City', neededBy: daysFromNow(10), notes: '', createdAt: now });

// 12 months of reference prices for 4 crops.
const base = { Tomato: 40, Eggplant: 50, Cabbage: 38, Onion: 95 };
for (let m = 11; m >= 0; m--) {
  const d = new Date(now.getFullYear(), now.getMonth() - m, 1);
  const month = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  for (const [crop, price] of Object.entries(base)) {
    const wobble = Math.round(Math.sin(m + crop.length) * 600) / 100;
    await setDoc(`prices/${crop}_${month}`, { crop, month, price: price + wobble, enteredBy: adminId, enteredAt: now });
  }
}

console.log('Demo data ready. Log in as farmer@demo.ph, buyer@demo.ph or admin@demo.ph (password demo1234).');
