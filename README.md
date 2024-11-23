TLDR: You will be able to commit your secrets straight to git, use them almost like constants in your code and not worry about syncing/sharing your secrets between various devs/environments. Eg you'd assign an age private key as the sole secret to every environment and it would be used to decrypt all the other secrets in provider-independent fashion.


```js
import secrets_encrypted from "./secrets.enc.json" with { type: "json" };
import { decrypt } from "jsr:@tarasglek/age-armored-decrypt"

const secrets = JSON.parse(await decrypt(secrets_encrypted));
console.log(secrets.SECRET_TOKEN)
```

# How it works

This library is a recipe to get [SOPS](https://github.com/getsops/sops)-like (but without nice git diffs) functionality with just [age](https://github.com/FiloSottile/age).

The encrypted secrets are stored as follows:
1. Your secrets are encrypted using [age-armored](https://pkg.go.dev/filippo.io/age/armor) format, which looks like text with "-----BEGIN AGE ENCRYPTED FILE-----" markers around base64 encrypted payload.
2. This age-encrypted output is then stored as a JSON string in a .json file, allowing it to be imported directly in JavaScript/TypeScript using:

```js
import secrets_encrypted from "./secrets.enc.json" with { type: "json" };
```

```
+----------------------------------------+
|  JSON String                           |
| "-----BEGIN AGE ENCRYPTED FILE-----\n  |
|  +------------------------------------+|
|  |  Age Encrypted Armored Content     ||
|  |  +--------------------------------+||
|  |  |  Inner JSON                    |||
|  |  |  {                             |||
|  |  |    "key1": "secret1",          |||
|  |  |    "key2": "secret2",          |||
|  |  |    "key3": "secret3",          |||
|  |  |    "key4": "secret4"           |||
|  |  |  }                             |||
|  +------------------------------------+|
|  -----END AGE ENCRYPTED FILE-----"     |
+----------------------------------------+
```

Sample encrypted file: [example/encrypted/secrets.enc.json](example/encrypted/secrets.enc.json)

# Tutorial

If you aren't familiar with encryption you can roughly map "private key" to password and "public key" to username.

Adapted from https://htmlpreview.github.io/?https://github.com/FiloSottile/age/blob/main/doc/age.1.html#EXAMPLES

## Create a key per recipient(eg each person or environment that needs to decrypt)
```sh
# generate new age private key, this is equivalent to a password. Treat accordingly
age-keygen -o key.txt
# view key, without comments
grep -v \# key.txt
```

Load private key into env var, ignore comments
```sh
export SOPS_AGE_KEY=$(grep -v \# key.txt)
```

You can also save the private key into .env
```sh
echo SOPS_AGE_KEY=$SOPS_AGE_KEY > .env
```

Create .sops.yaml with the public keys of all recipients (people/environments) that should be able to decrypt
```sh
cat > .sops.yaml <<'EOF'
creation_rules:
  - key_groups:
    - age: 
      
EOF
```

Add every recipient's public key:
```sh
echo  "      -" $(echo $SOPS_AGE_KEY | age-keygen -y) "# helpful comment with description of recipient" >> .sops.yaml
```

Note `age-keygen -y` converts private into public keys.

You should end up a .sops.yaml like
```yaml
creation_rules:
  - key_groups:
      - age:  
        - age1ql5yrumda99thhuensk3up94c426n6tcujvaxcuzhdrj76npacrq3eca7e # deno deploy
        - age1uhqrshhr4pguj5qn4krdhrnrxkatrsz7ckhamshdrsdpzmv0qursvmz8d9 # smallweb
```

### Now we are ready to encrypt
Create secrets.json with your unencrypted secrets:
```sh
cat << EOF > secrets.json
{
  "hello": "world",
  "bye": "now"
}
EOF
```

Use scripts from [example](https://github.com/tarasglek/age-armored-decrypt/tree/main/example) dir to encrypt/decrypt using age binary:
```sh
example/sops_encrypt.sh < secrets.json > secrets.enc.json
```

Encrypted `secrets.enc.json` file should now contain an age-encrypted payload encased within a valid JSON string. 
```json
"-----BEGIN AGE ENCRYPTED FILE-----\nYWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzOURFMDRTbGFMemoyR1Np\nYnNjWE9TUkN1cFhNYVJDcCtZWjFlZEFtMkNJCnhXaVFiWk1tMFBZaVNVa2hNcDg1\nQ28wUk5qbmh0d0E4dXVwMnE0b3FPYk0KLT4gWDI1NTE5IGVJRTFQWXdvOE54NXdC\nNStFNXVVM3FNU3FkMzlQWXVPQkQyeCt1cW5SU2MKMENKYy93ZTI5VHR4VzVjUXpE\nUklKc1F6Ull6T3NMUTh6R1k1Yzc1c0ZGOAotLS0gc2FwZG1kUE9kZCtCZ3NSNWlN\nNkVyMlZhSmlweFAzUS80UXdvYytFR0lYRQqzSC7n9p84cSBaJnKd/3AAoGtKWUnZ\n1lT6V2dWWApCeEh2pcfEX+iIM8ZsAmws8fNqDS+a7SB4dQaHjGdmGr0NvSRr82Ts\nUw==\n-----END AGE ENCRYPTED FILE-----\n"
```

Can decrypt it with shell:
```sh
examples/sops_decrypt.sh < secrets.enc.json
```

You can now include the encrypted secrets and decrypt them wherever the corresponding SOPS_AGE_KEY env var is set.

Note: For decryption to work, the SOPS_AGE_KEY environment variable must contain one of the private keys corresponding to the public keys listed in .sops.yaml.

```ts
import secrets_encrypted from "./secrets.enc.json" with { type: "json" };
import { decrypt } from "jsr:@tarasglek/age-armored-decrypt"

const secrets = JSON.parse(await decrypt(secrets_encrypted));
console.log(secrets.hello)
```

You can now briefly commit encrypted secrets and recipients to git
```sh
git add ./secrets.enc.json .sops.yaml
```

### Inspiration

JS code derived from https://github.com/humphd/sops-age

