import secrets_encrypted from "./example/encrypted/secrets.enc.json" with { type: "json" };
import { decrypt } from "./mod.ts";
await decrypt(secrets_encrypted)