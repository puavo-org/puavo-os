/*
 * Kernel module for the verification and signing pipeline.
 *
 * Provides the crypto backend using linux/crypto.h and
 * exposes an ioctl interface for userspace to submit
 * signing requests.
 *
 * Keys are provisioned at runtime via the LOAD_KEYS
 * ioctl. The module does not accept signing requests
 * until keys have been loaded.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <crypto/hash.h>
#include <crypto/sig.h>
#include <linux/mutex.h>

#include "core.h"
#include "ioctl.h"
#include "log.h"

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Puavo");
MODULE_DESCRIPTION("Puavo Kernel Command-Line Parameter Signer Module");

// Maximum accepted size for DER-encoded keys
#define MAX_KEY_SIZE 4096

// Maximum accepted size for a PE addon binary
#define MAX_PE_SIZE (1024 * 1024)

// Maximum accepted size for kernel parameters string
#define MAX_PARAMETERS_SIZE 4096

// Maximum accepted size for server authorization signature
#define MAX_AUTHORIZATION_SIZE 1024

// Maximum accepted size for authenticated attributes DER
#define MAX_ATTRIBUTES_SIZE 4096

// Maximum accepted size for IDC DER blob
#define MAX_IDC_SIZE 4096

// Maximum size for the output RSA signature buffer
#define MAX_SIGNATURE_SIZE 512

// Protects concurrent access to the key storage below
static DEFINE_MUTEX(keys_mutex);

// Server public key in DER format, used to verify
// that parameter change authorizations are genuine
static uint8_t* server_public_key_data;
static size_t server_public_key_size;

// Device Secure Boot private key in DER format, used
// to produce Authenticode signatures on UKI addons
static uint8_t* secure_boot_private_key_data;
static size_t secure_boot_private_key_size;

// Set to true after keys have been provisioned via
// the LOAD_KEYS ioctl
static bool are_keys_loaded;

// Computes SHA-256 of the given data using the kernel API.
static int kernel_sha256(const uint8_t* data, size_t length,
                         uint8_t output[SHA256_DIGEST_SIZE]) {
  struct crypto_shash* hash_transform;
  struct shash_desc* hash_descriptor;
  int result;

  // Allocate a synchronous hash transform for SHA-256
  hash_transform = crypto_alloc_shash("sha256", 0, 0);
  if (IS_ERR(hash_transform)) {
    return PTR_ERR(hash_transform);
  }

  // Allocate the hash descriptor with space for the
  // algorithm-specific context appended after the
  // descriptor header
  hash_descriptor =
      kzalloc(sizeof(*hash_descriptor) + crypto_shash_descsize(hash_transform),
              GFP_KERNEL);
  if (!hash_descriptor) {
    crypto_free_shash(hash_transform);
    return -ENOMEM;
  }

  // Compute the digest in a single call
  hash_descriptor->tfm = hash_transform;
  result = crypto_shash_digest(hash_descriptor, data, length, output);

  // Free the hash descriptor and the hash transform
  kfree(hash_descriptor);
  crypto_free_shash(hash_transform);
  return result;
}

// Verifies an RSA-PKCS1v15-SHA256 signature using the
// kernel API. Hashes the data with
// SHA-256 first, then verifies the signature against
// that digest.
static int kernel_rsa_verify(const uint8_t* key_data, size_t key_size,
                             const uint8_t* data, size_t data_size,
                             const uint8_t* signature, size_t signature_size) {
  uint8_t digest[SHA256_DIGEST_SIZE];
  struct crypto_sig* rsa_transform;
  int result;

  LOG_INFO(
      "rsa_verify: key %zu bytes, data %zu bytes, "
      "sig %zu bytes",
      key_size, data_size, signature_size);

  // Hash the data to produce the digest that was signed
  result = kernel_sha256(data, data_size, digest);
  if (result) {
    LOG_ERROR("sha256 failed: %d\n", result);
    return result;
  }

  // Allocate RSA with PKCS1v15 padding and SHA-256
  rsa_transform = crypto_alloc_sig("pkcs1pad(rsa,sha256)", 0, 0);
  if (IS_ERR(rsa_transform)) {
    LOG_ERROR("alloc sig failed: %ld\n", PTR_ERR(rsa_transform));
    return PTR_ERR(rsa_transform);
  }

  // Load the DER-encoded public key into the transform
  result = crypto_sig_set_pubkey(rsa_transform, key_data, key_size);
  if (result) {
    LOG_ERROR("set_pub_key failed: %d\n", result);
    crypto_free_sig(rsa_transform);
    return result;
  }

  // Verify that the signature matches the digest
  result = crypto_sig_verify(rsa_transform, signature, signature_size, digest,
                             SHA256_DIGEST_SIZE);

  LOG_INFO("rsa_verify result: %d\n", result);

  // Free the RSA transform
  crypto_free_sig(rsa_transform);
  return result;
}

// Signs a pre-computed SHA-256 digest using RSA with
// PKCS1v15 padding via the kernel API.
// On success, writes the signature to signature_out and
// updates signature_size_out with the actual size.
static int kernel_rsa_sign_digest(const uint8_t* key_data, size_t key_size,
                                  const uint8_t* digest, uint8_t* signature_out,
                                  size_t* signature_size_out) {
  struct crypto_sig* rsa_transform;
  int result;

  LOG_INFO("rsa_sign: key %zu bytes\n", key_size);

  // Allocate RSA with PKCS1v15 padding and SHA-256
  rsa_transform = crypto_alloc_sig("pkcs1pad(rsa,sha256)", 0, 0);
  if (IS_ERR(rsa_transform)) {
    LOG_ERROR("sign alloc failed: %ld\n", PTR_ERR(rsa_transform));
    return PTR_ERR(rsa_transform);
  }

  // Load the DER-encoded private key into the transform
  result = crypto_sig_set_privkey(rsa_transform, key_data, key_size);
  if (result) {
    LOG_ERROR("set_priv_key failed: %d\n", result);
    crypto_free_sig(rsa_transform);
    return result;
  }

  // Check that the output buffer is large enough
  unsigned int max_size = crypto_sig_maxsize(rsa_transform);
  LOG_INFO("rsa_sign: maxsize %u\n", max_size);

  if (max_size > *signature_size_out) {
    crypto_free_sig(rsa_transform);
    return -ENOSPC;
  }

  // Produce the RSA signature over the digest
  result = crypto_sig_sign(rsa_transform, digest, SHA256_DIGEST_SIZE,
                           signature_out, max_size);
  LOG_INFO("rsa_sign result: %d\n", result);

  // The return value convention changed between kernel
  // versions:
  //   6.12: returns 0 on success, signature fills maxsize
  //   6.18: returns signature size on success (positive)
  // Handle both: positive means actual size, zero means
  // the signature is exactly max_size bytes.
  if (result > 0) {
    *signature_size_out = result;
    result = 0;
  } else if (result == 0) {
    *signature_size_out = max_size;
  }

  crypto_free_sig(rsa_transform);
  return result;
}

static const struct sign_crypto_backend kernel_backend = {
    .sha256 = kernel_sha256,
    .rsa_verify = kernel_rsa_verify,
    .rsa_sign_digest = kernel_rsa_sign_digest,
};

// Provisions the server public key and device Secure
// Boot private key into the module. Must be called
// before any signing requests are accepted.
static long handle_load_keys(unsigned long argument) {
  struct puavo_command_line_load_keys_ioctl request;
  uint8_t* new_server_public_key = NULL;
  uint8_t* new_secure_boot_private_key = NULL;
  int result;

  // Copy the ioctl request structure from userspace
  if (copy_from_user(&request, (void __user*)argument, sizeof(request))) {
    return -EFAULT;
  }

  // Reject unreasonably large keys
  if (request.server_public_key_size > MAX_KEY_SIZE ||
      request.secure_boot_private_key_size > MAX_KEY_SIZE) {
    return -EINVAL;
  }

  // Allocate kernel buffers for both keys
  new_server_public_key = kmalloc(request.server_public_key_size, GFP_KERNEL);
  new_secure_boot_private_key =
      kmalloc(request.secure_boot_private_key_size, GFP_KERNEL);

  if (!new_server_public_key || !new_secure_boot_private_key) {
    result = -ENOMEM;
    goto error;
  }

  // Copy the key data from userspace into kernel buffers
  if (copy_from_user(new_server_public_key,
                     (void __user*)request.server_public_key_data,
                     request.server_public_key_size) ||
      copy_from_user(new_secure_boot_private_key,
                     (void __user*)request.secure_boot_private_key_data,
                     request.secure_boot_private_key_size)) {
    result = -EFAULT;
    goto error;
  }

  // Replace any previously loaded keys under the mutex
  mutex_lock(&keys_mutex);

  kfree(server_public_key_data);
  kfree(secure_boot_private_key_data);

  server_public_key_data = new_server_public_key;
  server_public_key_size = request.server_public_key_size;
  secure_boot_private_key_data = new_secure_boot_private_key;
  secure_boot_private_key_size = request.secure_boot_private_key_size;
  are_keys_loaded = true;

  mutex_unlock(&keys_mutex);

  // Report success back to userspace
  request.result = 0;
  if (copy_to_user((void __user*)argument, &request, sizeof(request))) {
    return -EFAULT;
  }

  LOG_INFO(
      "keys loaded (server %zu bytes, secure boot "
      "%zu bytes)\n",
      server_public_key_size, secure_boot_private_key_size);
  return 0;

error:
  kfree(new_server_public_key);
  kfree(new_secure_boot_private_key);
  return result;
}

// Executes the verify-and-sign pipeline on a signing
// request from userspace. Returns the pipeline result
// code in the ioctl structure (not as the ioctl return
// value, which is reserved for system errors).
static long handle_sign(unsigned long user_argument) {
  struct puavo_command_line_sign_ioctl request_ioctl;
  struct sign_request request;
  uint8_t* pe_data = NULL;
  char* parameters = NULL;
  uint8_t* authorization = NULL;
  uint8_t* attributes_der = NULL;
  uint8_t* idc_data = NULL;
  uint8_t* signature_buffer = NULL;
  int result;

  // Copy the ioctl request structure from userspace
  if (copy_from_user(&request_ioctl, (void __user*)user_argument,
                     sizeof(request_ioctl))) {
    return -EFAULT;
  }

  // Reject unreasonably large inputs
  if (request_ioctl.pe_size > MAX_PE_SIZE ||
      request_ioctl.parameters_size > MAX_PARAMETERS_SIZE ||
      request_ioctl.authorization_size > MAX_AUTHORIZATION_SIZE ||
      request_ioctl.attributes_der_size > MAX_ATTRIBUTES_SIZE ||
      request_ioctl.idc_size > MAX_IDC_SIZE) {
    return -EINVAL;
  }

  // Ensure keys have been provisioned before signing
  mutex_lock(&keys_mutex);
  if (!are_keys_loaded) {
    mutex_unlock(&keys_mutex);
    LOG_ERROR("keys not loaded\n");
    return -ENOKEY;
  }

  // Allocate kernel buffers for all input data
  pe_data = kmalloc(request_ioctl.pe_size, GFP_KERNEL);
  parameters = kmalloc(request_ioctl.parameters_size + 1, GFP_KERNEL);
  authorization = kmalloc(request_ioctl.authorization_size, GFP_KERNEL);
  attributes_der = kmalloc(request_ioctl.attributes_der_size, GFP_KERNEL);
  idc_data = kmalloc(request_ioctl.idc_size, GFP_KERNEL);
  signature_buffer = kzalloc(MAX_SIGNATURE_SIZE, GFP_KERNEL);

  if (!pe_data || !parameters || !authorization || !attributes_der ||
      !idc_data || !signature_buffer) {
    result = -ENOMEM;
    goto out;
  }

  // Copy all input data from userspace
  if (copy_from_user(pe_data, (void __user*)request_ioctl.pe_data,
                     request_ioctl.pe_size) ||
      copy_from_user(parameters, (void __user*)request_ioctl.parameters,
                     request_ioctl.parameters_size) ||
      copy_from_user(authorization, (void __user*)request_ioctl.authorization,
                     request_ioctl.authorization_size) ||
      copy_from_user(attributes_der, (void __user*)request_ioctl.attributes_der,
                     request_ioctl.attributes_der_size) ||
      copy_from_user(idc_data, (void __user*)request_ioctl.idc_data,
                     request_ioctl.idc_size)) {
    result = -EFAULT;
    goto out;
  }

  // Null-terminate the parameters string
  parameters[request_ioctl.parameters_size] = '\0';

  // Populate the pipeline request from ioctl inputs
  // and the module's provisioned keys
  request.pe_data = pe_data;
  request.pe_size = request_ioctl.pe_size;
  request.parameters = parameters;
  request.server_authorization = authorization;
  request.server_authorization_size = request_ioctl.authorization_size;
  request.attributes_der = attributes_der;
  request.attributes_der_size = request_ioctl.attributes_der_size;
  request.idc_data = idc_data;
  request.idc_size = request_ioctl.idc_size;
  request.server_public_key_der = server_public_key_data;
  request.server_public_key_der_size = server_public_key_size;
  request.secure_boot_private_key_der = secure_boot_private_key_data;
  request.secure_boot_private_key_der_size = secure_boot_private_key_size;
  request.signature_out = signature_buffer;
  request.signature_out_size = MAX_SIGNATURE_SIZE;

  LOG_INFO("server key %zu bytes, secure boot key %zu bytes\n",
           server_public_key_size, secure_boot_private_key_size);
  LOG_INFO(
      "pe %llu bytes, request parameters %llu bytes, authorization %llu "
      "bytes\n",
      request_ioctl.pe_size, request_ioctl.parameters_size,
      request_ioctl.authorization_size);

  // Run the verify-and-sign pipeline
  result = sign_verify_and_sign(&request, &kernel_backend);

  LOG_INFO("pipeline result: %d\n", result);

  // The pipeline result is returned inside the ioctl
  // structure, not as the ioctl return value. The ioctl
  // returns 0 on success or a negative errno for system
  // errors like EFAULT. Pipeline rejection codes are
  // not errno values.
  request_ioctl.result = result;

  // Copy the signature back to userspace on success
  if (result == SIGN_OK) {
    if (request.signature_out_size > request_ioctl.signature_out_size) {
      result = -ENOSPC;
      goto out;
    }
    if (copy_to_user((void __user*)request_ioctl.signature_out,
                     signature_buffer, request.signature_out_size)) {
      result = -EFAULT;
      goto out;
    }
    request_ioctl.signature_out_size = request.signature_out_size;
  }

  // Copy the updated ioctl structure back to userspace
  if (copy_to_user((void __user*)user_argument, &request_ioctl,
                   sizeof(request_ioctl))) {
    result = -EFAULT;
    goto out;
  }

  result = 0;

out:
  mutex_unlock(&keys_mutex);
  kfree(pe_data);
  kfree(parameters);
  kfree(authorization);
  kfree(attributes_der);
  kfree(idc_data);
  kfree(signature_buffer);
  return result;
}

// Dispatches ioctl commands to the appropriate handler.
static long puavo_command_line_signer_ioctl(struct file* file,
                                            unsigned int command,
                                            unsigned long user_argument) {
  switch (command) {
    case PUAVO_COMMANDLINE_SIGN_IOC_LOAD_KEYS:
      return handle_load_keys(user_argument);
    case PUAVO_COMMANDLINE_SIGN_IOC_SIGN:
      return handle_sign(user_argument);
    default:
      return -ENOTTY;
  }
}

static const struct file_operations puavo_command_line_signer_fops = {
    .owner = THIS_MODULE,
    .unlocked_ioctl = puavo_command_line_signer_ioctl,
};

static struct miscdevice puavo_command_line_signer_device = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "puavo-command-line-signer",
    .fops = &puavo_command_line_signer_fops,
};

// Registers the misc device and waits for key
// provisioning via the LOAD_KEYS ioctl.
static int __init puavo_command_line_signer_init(void) {
  int result;

  result = misc_register(&puavo_command_line_signer_device);
  if (result) {
    LOG_ERROR("misc_register failed\n");
    return result;
  }

  LOG_INFO("module loaded, waiting for keys\n");
  return 0;
}

// Frees provisioned keys and deregisters the misc device.
static void __exit puavo_command_line_signer_exit(void) {
  // Acquire the mutex to ensure no signing request is
  // in progress while we free the keys
  mutex_lock(&keys_mutex);

  kfree(secure_boot_private_key_data);
  kfree(server_public_key_data);
  are_keys_loaded = false;

  mutex_unlock(&keys_mutex);

  misc_deregister(&puavo_command_line_signer_device);
  LOG_INFO("module unloaded\n");
}

module_init(puavo_command_line_signer_init);
module_exit(puavo_command_line_signer_exit);
