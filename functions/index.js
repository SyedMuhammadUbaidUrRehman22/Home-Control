const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * 1. Log device status changes
 */
exports.logDeviceStatusChange = functions.firestore
  .document("devices/{deviceId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.isOn === after.isOn) {
      return null;
    }

    return db.collection("device_logs").add({
      deviceId: context.params.deviceId,
      deviceName: after.name || "Unknown Device",
      room: after.room || "Unknown Room",
      oldStatus: before.isOn,
      newStatus: after.isOn,
      userId: after.userId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

/**
 * 2. Turn off all devices for current user
 */
exports.turnOffAllDevices = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in.",
    );
  }

  const userId = context.auth.uid;

  const snapshot = await db
    .collection("devices")
    .where("userId", "==", userId)
    .get();

  const batch = db.batch();

  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {
      isOn: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();

  return {
    success: true,
    updatedDevices: snapshot.docs.length,
  };
});
