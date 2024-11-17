This is a way to get [SOPS](https://github.com/getsops/sops)-like (but without nice git diffs) functionality with just [age](https://github.com/FiloSottile/age).

TLDR: You will be able to commit your secrets straight to git and not worry about syncing/sharing your secrets between various devs/environments.

# Tutorial
Adapted from https://htmlpreview.github.io/?https://github.com/FiloSottile/age/blob/main/doc/age.1.html#EXAMPLES

## Create a key per recipient(eg each person or environment that needs to decrypt)
```sh
# generate new age private key, this is equivalent to a password. Treat accordingly
age-keygen -o key.txt
# view key, without comments
grep -v \# key.txt
```

```sh
# load private key into env var, ignore comments
export SOPS_AGE_KEY=$(grep -v \# key.txt)
```

Create .sops.yaml with all of the recipients that we want to be able to decrypt
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

You should end up a .sops.yaml like
```yaml
creation_rules:
  - key_groups:
      - age:  
        - age1ql5yrumda99thhuensk3up94c426n6tcujvaxcuzhdrj76npacrq3eca7e # deno deploy
        - age1uhqrshhr4pguj5qn4krdhrnrxkatrsz7ckhamshdrsdpzmv0qursvmz8d9 # smallweb
```

### Now we are ready to encrypt
make a secrets.json
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

