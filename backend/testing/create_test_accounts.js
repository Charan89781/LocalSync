const apiKey = 'AIzaSyDNvjWcYNHJa-3S46DmTZ2bHqMziQcUgeU';
const projectId = 'localsync-d68dc';

async function registerOrLogin(email, password, displayName) {
  console.log(`\n==================================================`);
  console.log(`Setting up user: ${email}...`);
  
  // Try sign up first
  let res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true })
  });
  
  let data = await res.json();
  let idToken = '';
  let localId = '';

  if (data.error && data.error.message === 'EMAIL_EXISTS') {
    console.log(`Email ${email} already exists. Logging in to fetch token...`);
    res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true })
    });
    data = await res.json();
  }

  if (data.error) {
    throw new Error(`Authentication failed for ${email}: ${JSON.stringify(data.error)}`);
  }

  idToken = data.idToken;
  localId = data.localId;
  console.log(`Authenticated ${email} successfully! UID: ${localId}`);

  // Now write/update Firestore user profile
  const userDocUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${localId}`;
  
  let role = 'resident';
  if (email.includes('admin')) {
    role = 'admin';
  } else if (email.includes('moderator')) {
    role = 'moderator';
  }

  const userDocPayload = {
    fields: {
      email: { stringValue: email },
      name: { stringValue: displayName },
      role: { stringValue: role },
      isVerified: { booleanValue: true },
      trustScore: { doubleValue: 5.0 },
      totalHelps: { integerValue: 0 },
      totalPosts: { integerValue: 0 },
      settings: {
        mapValue: {
          fields: {
            enablePushNotifications: { booleanValue: true },
            showLocation: { booleanValue: true },
            darkMode: { booleanValue: false },
            biometricLock: { booleanValue: false }
          }
        }
      }
    }
  };

  console.log(`Writing Firestore profile for ${email}...`);
  const firestoreRes = await fetch(userDocUrl, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${idToken}`
    },
    body: JSON.stringify(userDocPayload)
  });

  if (!firestoreRes.ok) {
    const errText = await firestoreRes.text();
    throw new Error(`Failed to write Firestore user doc: ${errText}`);
  }

  console.log(`Firestore user profile written successfully!`);
  return { uid: localId, idToken };
}

async function createTestBusiness(ownerUid, ownerToken) {
  console.log(`\n==================================================`);
  console.log(`Creating test business listing for shop keeper owner...`);
  
  const businessPayload = {
    fields: {
      name: { stringValue: "Test Bakery & Cafe" },
      category: { stringValue: "Food" },
      description: { stringValue: "Freshly baked bread, pastries, and gourmet coffee served daily. Friendly neighborhood spot." },
      address: { stringValue: "Suite 404, Building B, Green Society" },
      phoneNumber: { stringValue: "+1-555-0144" },
      imageUrl: { stringValue: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500" },
      rating: { doubleValue: 4.9 },
      ownerId: { stringValue: ownerUid },
      isVerified: { booleanValue: true },
      website: { stringValue: "www.testbakerycafe.com" },
      businessHours: { stringValue: "7 AM - 8 PM" }
    }
  };

  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/businesses`;
  
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${ownerToken}`
    },
    body: JSON.stringify(businessPayload)
  });

  if (!res.ok) {
    const errText = await res.text();
    console.warn(`Could not create test business automatically: ${errText}`);
    console.log(`Note: This is normal if security rules block business creation from client, but the user account is fully created!`);
  } else {
    const data = await res.json();
    console.log(`Successfully created test business "Test Bakery & Cafe"! Document ID: ${data.name.split('/').pop()}`);
  }
}

async function run() {
  try {
    // 1. Create Test Resident
    await registerOrLogin('test_resident@localsync.com', 'Resident123', 'Test Resident');

    // 2. Create Test Shop Keeper
    const shopkeeper = await registerOrLogin('test_shopkeeper@localsync.com', 'Shopkeeper123', 'Test Shop Keeper');

    // 3. Create Test Admin
    await registerOrLogin('test_admin@localsync.com', 'Admin123', 'Test Admin');

    // 4. Populate test business listing for the Shop Keeper
    await createTestBusiness(shopkeeper.uid, shopkeeper.idToken);

    console.log(`\n==================================================`);
    console.log(`All accounts created successfully!`);
    console.log(`Credentials for login testing:`);
    console.log(`--------------------------------------------------`);
    console.log(`1. Test Resident:`);
    console.log(`   - Email:    test_resident@localsync.com`);
    console.log(`   - Password: Resident123`);
    console.log(`   - Role:     resident`);
    console.log(`--------------------------------------------------`);
    console.log(`2. Test Shop Keeper:`);
    console.log(`   - Email:    test_shopkeeper@localsync.com`);
    console.log(`   - Password: Shopkeeper123`);
    console.log(`   - Role:     resident (Business Owner)`);
    console.log(`   - Shop Name: "Test Bakery & Cafe" (auto-created)`);
    console.log(`--------------------------------------------------`);
    console.log(`3. Test Admin:`);
    console.log(`   - Email:    test_admin@localsync.com`);
    console.log(`   - Password: Admin123`);
    console.log(`   - Role:     admin`);
    console.log(`==================================================\n`);
  } catch (err) {
    console.error(`Error during account creation:`, err);
  }
}

run();
