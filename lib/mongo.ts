import { MongoClient, type Db } from "mongodb";

const globalForMongo = globalThis as unknown as { mongoClient?: MongoClient };

function getClient() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error("MONGODB_URI is not configured");
  return globalForMongo.mongoClient ?? new MongoClient(uri);
}

export async function auditEvent(event: Record<string, unknown>) {
  const client = getClient();
  if (!globalForMongo.mongoClient) globalForMongo.mongoClient = client;
  await client.connect();
  const database: Db = client.db(process.env.MONGODB_DATABASE ?? "hotel_reservations_audit");
  await database.collection("booking_events").insertOne({
    ...event,
    occurredAt: new Date(),
  });
}
