#!/bin/bash
# Checks the command-line manager against a software TPM: the device key
# is loaded, the server authorizes addons, and the device signs what the
# server authorized, and nothing else.
#
# Builds what it needs from the source tree. Needs swtpm, the libtpms
# TCTI, tpm2-tools, ukify, sbverify, jq and openssl.
#
# Usage: command-line-manager.sh
set -u

script_directory=$(cd "$(dirname "$0")" && pwd)
component_directory=$(cd "${script_directory}/.." && pwd)

work=$(mktemp -d)
swtpm_pid=''
cleanup() {
  [ -z "$swtpm_pid" ] || kill "$swtpm_pid" 2>/dev/null
  rm -rf "$work"
}
trap cleanup EXIT

failures=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

assert() {
  local description=$1
  shift
  if "$@" >"${work}/output" 2>&1; then
    pass "$description"
  else
    fail "$description"
    cat "${work}/output"
  fi
}

assert_failure() {
  local description=$1
  shift
  if "$@" >"${work}/output" 2>&1; then
    fail "$description"
  else
    pass "$description"
  fi
}

echo 'Building...'
make -C "$component_directory" all >/dev/null 2>&1 \
  || { echo 'error: failed to build the signing request programs' >&2; exit 1; }

mkdir -p "${work}/bin"
ln -s "${component_directory}/request/puavo-command-line-sign-request" \
  "${component_directory}/assemble/puavo-command-line-sign-assemble" \
  "${work}/bin/"

# The scripts as installed.
for script in "${component_directory}"/tpm/*; do
  ln -s "$script" \
    "${work}/bin/puavo-command-line-manager-$(basename "$script")"
done

# The socket TPM has no resource manager. Like one, flush the transient
# objects every tool leaves behind, so the three object slots suffice.
cat > "${work}/bin/tpm2" <<'TOOL'
#!/bin/sh
/usr/bin/tpm2 "$@"
status=$?
/usr/bin/tpm2 flushcontext -t >/dev/null 2>&1
exit $status
TOOL
chmod +x "${work}/bin/tpm2"
export PATH="${work}/bin:${PATH}"

# The TPM listens on a free pair of ports.
port=$((20000 + RANDOM % 20000))
mkdir -p "${work}/tpm"
swtpm socket --tpm2 --tpmstate "dir=${work}/tpm" \
  --server "type=tcp,port=${port}" --ctrl "type=tcp,port=$((port + 1))" \
  --flags startup-clear &
swtpm_pid=$!
sleep 1
export TPM2TOOLS_TCTI="swtpm:port=${port}"

storage_key=0x81000001
published="${work}/published"
export PUAVO_SERVER_PUBLIC_KEY="${work}/server.pub"
export PUAVO_COMMANDLINE_DIRECTORY=$published

# A key directory as the Boot Trust Manager and older systems have it.
new_device() {
  mkdir -p "${work}/$1"
  openssl req -x509 -newkey rsa:2048 -nodes -days 1 -sha256 \
    -keyout "${work}/$1/secure-boot.priv" -out "${work}/$1/secure-boot.pem" \
    -subj "/CN=Puavo Device Secure Boot Key/" 2>/dev/null
}

openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 \
  -out "${work}/server.priv"
openssl pkey -in "${work}/server.priv" -pubout -out "${work}/server.pub" \
  2>/dev/null
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 \
  -out "${work}/rogue.priv"
new_device device
new_device other-device
device_certificate="${work}/device/secure-boot.pem"

# Removes what earlier commands left, which a resource manager would.
flush() {
  tpm2 flushcontext -t >/dev/null 2>&1
  tpm2 flushcontext -l >/dev/null 2>&1
  tpm2 flushcontext -s >/dev/null 2>&1
}

load() {
  flush
  puavo-command-line-manager-load "${work}/$1"
}

storage_key_name() {
  tpm2 readpublic -c "$storage_key" -n "${work}/name" >/dev/null 2>&1 \
    && od -An -tx1 "${work}/name" | tr -d ' \n'
}

# The counter value a bundle authorizes up to, the device's current one
# unless given.
counter_limit=''

authorize() {
  local commandline=$1 certificate=$2 server_key=$3 bundle=$4
  ukify build --section=".cmdline:${commandline}" \
    --output="${work}/addon.efi" >/dev/null
  puavo-command-line-manager-authorize "${work}/addon.efi" "$certificate" \
    "$server_key" "${counter_limit:-$(puavo-command-line-manager-counter)}" \
    "$bundle"
}

sign() {
  flush
  puavo-command-line-manager-sign "${work}/device" "$1" "$2"
}

assert 'load the device key into the TPM' load device
first_storage_key=$(storage_key_name)
assert 'the storage key is made' test -n "$first_storage_key"
assert 'the imported key is published' \
  test -s "${published}/device.pub" -a -s "${published}/device.priv"
assert 'the server key in use is published' \
  cmp "${work}/server.pub" "${published}/server.pub"
assert 'loading again works' load device
assert 'loading again keeps the storage key' \
  test "$(storage_key_name)" = "$first_storage_key"

authorize 'quiet splash' "$device_certificate" "${work}/server.priv" \
  "${work}/bundle.json"
assert 'sign the authorized addon' \
  sign "${work}/bundle.json" "${work}/signed.efi"
assert 'signed addon verifies against the device certificate' \
  sbverify --cert "$device_certificate" "${work}/signed.efi"
assert 'signed addon holds the authorized command-line' \
  sh -c "objcopy -O binary --only-section=.cmdline '${work}/signed.efi' \
    '${work}/cmdline' && grep -qx 'quiet splash' '${work}/cmdline'"

authorize 'break=mount' "$device_certificate" "${work}/rogue.priv" \
  "${work}/rogue.json"
assert_failure 'refuse a policy signed by another key' \
  sign "${work}/rogue.json" "${work}/refused.efi"

# The authorized policy, but another addon or digest swapped in.
jq --arg addon "$(jq -r .addon "${work}/rogue.json")" '.addon = $addon' \
  "${work}/bundle.json" > "${work}/swapped.json"
sign "${work}/swapped.json" "${work}/swapped.efi" >/dev/null 2>&1
assert_failure 'a swapped addon gets no valid signature' \
  sbverify --cert "$device_certificate" "${work}/swapped.efi"
jq --arg digest "$(jq -r .digest "${work}/rogue.json")" '.digest = $digest' \
  "${work}/bundle.json" > "${work}/swapped.json"
assert_failure 'refuse a digest the policy does not name' \
  sign "${work}/swapped.json" "${work}/refused.efi"

authorize 'quiet splash' "${work}/other-device/secure-boot.pem" \
  "${work}/server.priv" "${work}/other.json"
assert_failure 'refuse a bundle authorized for another device' \
  sign "${work}/other.json" "${work}/refused.efi"

# Root holds the TPM. A password session must not be enough.
flush
head -c 32 /dev/urandom > "${work}/any-digest"
tpm2 load -C "$storage_key" -u "${published}/device.pub" \
  -r "${published}/device.priv" -c "${work}/key.ctx" -Q
assert_failure 'root cannot sign with a password session' \
  tpm2 sign -c "${work}/key.ctx" -g sha256 -s rsassa -d -o "${work}/root.sig" \
  "${work}/any-digest"

assert 'an authorized bundle signs again' \
  sign "${work}/bundle.json" "${work}/signed-again.efi"

# Each bundle holds while the counter is at most its value, and signing
# raises the counter to it, so a newer bundle ends the older ones.
start=$(puavo-command-line-manager-counter)
assert 'signing leaves the counter at the bundle value' \
  test "$(jq -r .counter "${work}/bundle.json")" = "$start"

counter_limit=$((start + 1))
authorize 'quiet' "$device_certificate" "${work}/server.priv" \
  "${work}/newer.json"
assert 'sign a newer bundle' \
  sign "${work}/newer.json" "${work}/newer.efi"
assert 'the counter rose to the newer bundle value' \
  test "$(puavo-command-line-manager-counter)" = "$((start + 1))"
assert_failure 'refuse the older bundle once a newer one is used' \
  sign "${work}/bundle.json" "${work}/refused.efi"
grep -q 'newer authorization' "${work}/output" \
  && pass 'the refusal is the counter' \
  || fail 'the refusal is the counter'

counter_limit=$((start + 4))
authorize 'quiet splash' "$device_certificate" "${work}/server.priv" \
  "${work}/jump.json"
assert 'sign a bundle several values ahead' \
  sign "${work}/jump.json" "${work}/jump.efi"
assert 'the counter rose all the way' \
  test "$(puavo-command-line-manager-counter)" = "$((start + 4))"

# Accepted residual: root can raise the counter and block the current
# bundle until a newer one, no more than deleting the addon.
flush
tpm2 nvincrement 0x010c3d15
assert_failure 'a counter raised past the bundle blocks it' \
  sign "${work}/jump.json" "${work}/refused.efi"
counter_limit=''

# Without a configured server key, the placeholder keys stand in for it.
rm -f "${published}/server.pub"
assert_failure 'load refuses without a server key' \
  env PUAVO_SERVER_PUBLIC_KEY="${work}/missing.pub" \
  puavo-command-line-manager-load "${work}/device"
assert 'make the placeholder keys' \
  env PUAVO_SERVER_PUBLIC_KEY="${work}/missing.pub" \
  puavo-command-line-manager-placeholder-keys
assert 'the placeholder keys are a pair' \
  sh -c "openssl pkey -in '${published}/server.priv' -pubout \
    | cmp - '${published}/server.pub'"
cp "${published}/server.priv" "${work}/placeholder-server.priv"
assert 'no placeholder keys with a configured server key' \
  sh -c "puavo-command-line-manager-placeholder-keys \
    && cmp '${work}/placeholder-server.priv' '${published}/server.priv'"
assert 'load with the placeholder key' \
  env PUAVO_SERVER_PUBLIC_KEY="${work}/missing.pub" \
  puavo-command-line-manager-load "${work}/device"
authorize 'quiet' "$device_certificate" \
  "${published}/server.priv" "${work}/placeholder-key.json"
assert 'sign a bundle authorized with the placeholder key' \
  sign "${work}/placeholder-key.json" "${work}/placeholder-key.efi"

cp "${published}/device.pub" "${work}/first-device.pub"
assert 'load another device key' load other-device
assert_failure 'the published key is the new one' \
  cmp -s "${work}/first-device.pub" "${published}/device.pub"

# A storage key whose secret is known outside the TPM would reveal the
# device key.
flush
tpm2 evictcontrol -C o -c "$storage_key" >/dev/null 2>&1
tpm2 createprimary -C o -c "${work}/primary.ctx" -Q
tpm2 create -C "${work}/primary.ctx" -G ecc256:aes128cfb \
  -a 'userwithauth|restricted|decrypt|sensitivedataorigin' \
  -u "${work}/foreign.pub" -r "${work}/foreign.priv" -Q
tpm2 load -C "${work}/primary.ctx" -u "${work}/foreign.pub" \
  -r "${work}/foreign.priv" -c "${work}/foreign.ctx" -Q
tpm2 evictcontrol -C o -c "${work}/foreign.ctx" "$storage_key" >/dev/null
flush
foreign_name=$(storage_key_name)
assert_failure 'load refuses a storage key that can leave the TPM' \
  load device
assert 'the foreign storage key stays' \
  test "$(storage_key_name)" = "$foreign_name"

echo "${failures} failure(s)"
exit $((failures > 0))
