import age_promise from "age-encryption";
import { decodeBase64 } from "@std/encoding/base64";

const regex =
  /-----BEGIN AGE ENCRYPTED FILE-----\r?\n([\s\S]+?)\r?\n-----END AGE ENCRYPTED FILE-----/;

/** 
 * Decrypts armored age strings 
 * @param armoredValue armored age payload
 * @param options.SOPS_AGE_KEY you can pass the secret key here or fallback on SOPS_AGE_KEY env var
*/
export async function decrypt(armoredValue: string, options?: { SOPS_AGE_KEY?: string }): Promise<string> {
  let SOPS_AGE_KEY: string | undefined;
  if (!SOPS_AGE_KEY) {
    // see if there is process.env or Deno.env to get this var
    SOPS_AGE_KEY = (globalThis as any).process?.env?.SOPS_AGE_KEY ?? (globalThis as any).Deno?.env.get("SOPS_AGE_KEY");
  }
  if (!SOPS_AGE_KEY) {
    throw new Error("SOPS_AGE_KEY env is not set");
  }
  const matches = armoredValue.match(regex);
  if (!matches?.[1]) {
    throw new Error("unable to extract armored value");
  }
  const base64String = matches[1].trim();
  const binary = decodeBase64(base64String);

  const age = await age_promise();
  const decrypter = new age.Decrypter();
  decrypter.addIdentity(SOPS_AGE_KEY);
  const decrypted = decrypter.decrypt(binary, "uint8array");

  return new TextDecoder().decode(decrypted);
}
