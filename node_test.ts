import { readFileSync } from "node:fs";
import { decrypt } from "./mod.ts";

const secretsFile = readFileSync("./example/encrypted/secrets.enc.json", "utf8");
const secrets_encrypted = JSON.parse(secretsFile);
console.log(await decrypt(secrets_encrypted));
